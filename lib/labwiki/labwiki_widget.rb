
require 'omf_base/lobject'
require 'omf-web/widget'
require 'labwiki/column_widget'

module LabWiki

  # Thrown by a widget if it wants anotehr widget to handle the
  # action.
  #
  # @param widget_name name of widget to try
  # @param opts
  # @param opts action Override action to use on new widget
  #
  class RedirectWidget < LWException
    attr_reader :widget_name, :opts

    def initialize(widget_name, opts)
      @widget_name = widget_name
      @opts = opts
    end
  end

  class LWWidget < OMF::Base::LObject

    def self.init_session()
      if si = LabWiki::Configurator['session/default_plugins']
        top_widget = OMF::Web::SessionStore[:lw_widget, :rack] = self.new
        si.each do |opts|
          opts = opts.dup
          unless col = opts.delete(:column)
            raise "Missing 'column' declaration in config file's 'session/default_plugins' - #{opts}"
          end
          # TODO: Check if that's all there is
          unless action = opts.delete(:action)
            raise "Missing 'action' declaration in config file's 'session/default_plugins' - #{opts}"
          end
          col = col.to_sym
          opts[:repo_iterator] = OMF::Web::SessionStore[col, :repos]
          widget = top_widget.create_column_widget(col.to_sym, opts)
          widget.send(action, opts, nil)
        end
      end
    end

    attr_reader :plan_widget, :prepare_widget, :execute_widget

    def initialize()
      @widgets = {}
    end

    def column_widget(pos)
      @widgets[pos.to_sym]
    end

    def dispatch_to_column(col, action, params, req)
      action = "on_#{action}".to_sym
      params = expand_req_params(col, params, req)
      col_widget = @widgets[col] # currently shown widget

      case action
      when :on_new
        col_widget = nil
        action = :on_get_content
      when :on_get_widget
        if widget_id = params[:widget_id]
          unless col_widget && col_widget.widget_id == widget_id
            # if we can find it in the session store, use it
            col_widget = OMF::Web::SessionStore[widget_id, :widgets]
          end
        else
          col_widget = nil
        end
        action = :on_get_content
      else
        debug "dispatch params: #{params} - col_wgt: #{col_widget}"
        if widget_id = params[:widget_id]
          unless col_widget && col_widget.widget_id == widget_id
            if w = OMF::Web::SessionStore[widget_id, :widgets]
              # good we found an existing old one
              col_widget = @widgets[col] = w
            else
              raise OMF::Web::Rack::UnknownResourceException.new "Requesting unknown widget id '#{widget_id}::#{widget_id.class}'"
            end
          end
        elsif col_widget
          if url = params[:url] || (params[:params] || {})[:url]
            col_widget = nil if col_widget.content_url != url
          end
        end
      end
      unless col_widget
        col_widget = @widgets[col] = create_column_widget(col, params)
      end
      _dispatch_to_widget(col, col_widget, action, params, req)
    end

    def _dispatch_to_widget(col, widget, action, params, req)
      unless widget
        raise "Can't create widget for for column '#{col}' (#{params.inspect})"
      end
      unless widget.respond_to? action
        raise "Unknown action '#{action}' for widget '#{widget}'"
      end

      OMF::Web::SessionStore[widget.widget_id, :widgets] # just to reset expiration timer

      no_render = params.delete(:no_render)
      if action == :on_new
        action_reply = nil
      else
        debug "Calling '#{action} on '#{widget.class}' widget"
        begin
          action_reply = widget.send(action, params, req)
        rescue RedirectWidget => rex
          action = rex.opts[:action] ||= :on_get_content
          rex.opts[:repo_iterator] ||= params[:repo_iterator]
          rex.opts[:widget] ||= rex.widget_name
          debug "Redirect to '#{rex.widget_name}\##{action}' - #{rex.opts}"
          widget = create_column_widget(col, rex.opts)
          return _dispatch_to_widget(col, widget, action, rex.opts, req)
        end
      end

      res = widget.content_descriptor.dup
      if no_render
        res[:action_reply] = action_reply
      else
        r = OMF::Web::Theme::ColumnContentRenderer.new(widget, col)
        res[:html] = r.to_html
      end
      [res.to_json, "application/json"]
    end

    def create_column_widget(col, params)
      @widgets[col] = PluginManager.create_widget(col, params)
    end

    def expand_req_params(col, params, req)
      if cd = params[:content]
        params[:mime_type], params[:url] = Base64.decode64(cd).split('::')
        unless params[:mime_type] && params[:url]
          raise OMF::Web::Rack::MissingArgumentException.new "Can't decode 'content' parameter (#{cd}) - #{params}"
        end
        params[:content_descriptor] = cd
      elsif url = params[:content_url]
        params[:url] = url
        params[:mime_type] = 'unknown'
      end
      params[:repo_iterator] = OMF::Web::SessionStore[col, :repos]
      OMF::Web.deep_symbolize_keys(params)
    end



    def collect_data_sources(ds_set)
      @widgets.each_value do |w|
        w.collect_data_sources(ds_set)
      end
      ds_set
    end
  end
end
