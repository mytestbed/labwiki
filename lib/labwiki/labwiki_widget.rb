
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

      # col_widget = @widgets[col]
      # if action == :on_get_content
        # # that's the time to create a new widget if it doesn't exist yet, or
        # # if the requested content is different from before
        # if col_widget.nil? || (col_widget.content_url != params[:url])
          # col_widget = create_column_widget(col, params)
        # end
      # end
      col_widget = create_column_widget(col, params) # better create a new one for every request
      unless col_widget
        raise "Don't have widget for for column '#{col}' and action '#{action}' (#{params.inspect})"
      end
      unless col_widget.respond_to? action
        raise "Unknown action '#{action}' for column '#{col}'"
      end

      debug "Calling '#{action} on '#{col_widget.class}' widget"
      col_widget.send(action, params, req) || {}
      # res = col_widget.send(action, params, req) || {}
      # unless res.is_a? Hash
        # raise "Action '#{action}' for '#{col_widget}' is expected to return a hash, but returned type '#{res.class}'"
      # end

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
