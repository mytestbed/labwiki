
require 'omf_common/lobject'
require 'omf-web/widget'
require 'labwiki/column_widget'

module LabWiki
  class LWWidget < OMF::Common::LObject

    attr_reader :plan_widget, :prepare_widget, :execute_widget

    def initialize()
      @widgets = {}
    end

    def column_widget(pos)
      @widgets[pos.to_sym]
    end

    def dispatch_to_column(col, action, params, req)
      action = "on_#{action}".to_sym
      params = expand_req_params(params, req)

      puts "dispatch params: #{params}"
      col_widget = @widgets[col]
      if widget_id = params[:widget_id]
        unless col_widget && col_widget.widget_id == widget_id
          if w = OMF::Web::SessionStore[widget_id, :widgets]
            # good we found an existing old one
            col_widget = @widgets[col] = w
          else
            raise "Requesting unknown widget id '#{widget_id}::#{widget_id.class}' -- #{col_widget.inspect}"
          end
        end
      elsif col_widget
        if url = params[:url] || (params[:params] || {})[:url]
          col_widget = nil if col_widget.content_url != url
        end
      end
      unless col_widget
        col_widget = @widgets[col] = create_column_widget(col, params)
      end
      unless col_widget
        raise "Can't create widget for for column '#{col}' (#{params.inspect})"
      end
      unless col_widget.respond_to? action
        raise "Unknown action '#{action}' for column '#{col}'"
      end

      debug "Calling '#{action} on '#{col_widget.class}' widget"
      OMF::Web::SessionStore[col_widget.widget_id, :widgets] # just to reset expiration timer
      col_widget.send(action, params, req) || {}

      res = col_widget.content_descriptor.dup
      r = OMF::Web::Theme::ColumnContentRenderer.new(col_widget, col)
      res[:html] = r.to_html
      [res.to_json, "application/json"]
    end

    def create_column_widget(col, params)
      debug "Creating widget for '#{col}' from '#{params.inspect}'"
      @widgets[col] = PluginManager.create_widget(col, params)
    end

    def expand_req_params(params, req)
      if cd = params[:content]
        params[:mime_type], params[:url] = Base64.decode64(cd).split('::')
        unless params[:mime_type] && params[:url]
          raise OMF::Web::Rack::MissingArgumentException.new "Can't decode 'content' parameter (#{cd})"
        end
        params[:content_descriptor] = cd
      elsif url = params[:content_url]
        params[:url] = url
        params[:mime_type] = 'unknown'
      end
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
