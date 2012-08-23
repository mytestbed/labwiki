
require 'omf_common/lobject'
require 'omf-web/widget'
require 'labwiki/column_widget'
# require 'labwiki/plan_widget'
# require 'labwiki/prepare_widget'
# require 'labwiki/execute_widget'

module LabWiki     
  class LWWidget < OMF::Common::LObject
    # @@instance = nil
#     
    # def self.[](opts)
      # @@instance ||= self.new
    # end
    
    attr_reader :plan_widget, :prepare_widget, :execute_widget
    
    def initialize()
      @widgets = {}
      # @plan_widget = @widgets[:plan] = PlanWidget.new(:plan)
      # @prepare_widget = @widgets[:prepare] = PrepareWidget.new(:prepare)
      # @execute_widget = @widgets[:execute] = ExecuteWidget.new(:execute)
    end
    
    def column_widget(pos)
      @widgets[pos.to_sym]
    end
    
    def dispatch_to_column(col, action, params, req)
      action = "on_#{action}".to_sym
      params = expand_req_params(params, req)
      
      col_widget = @widgets[col]
      if action == :on_get_content
        # that's the time to create a new widget if it doesn't exist yet, or 
        # if the requested content is different from before
        if col_widget.nil? || (col_widget.content_url != params[:url])
          col_widget = create_column_widget(col, params)
        end
      end
      unless col_widget
        raise "Don't have widget for for column '#{col}' and action '#{action}' (#{params.inspect})"
      end
      unless col_widget.respond_to? action
        raise "Unknown action '#{action}' for column '#{col}'"
      end

      debug "Calling '#{action} on '#{col_widget.class}' widget"
      col_widget.send(action, params, req)
      
      r = OMF::Web::Theme::ColumnContentRenderer.new(col_widget, col)
      [r.to_html, "text/html"]
      
    end
    
    def create_column_widget(col, params)
      debug "Creating widget for '#{col}' from '#{params.inspect}'"
      @widgets[col] = Plugin.create_widget(col, params)
    end
    
    def expand_req_params(params, req)
      if cd = params[:content_descriptor] = params[:content]
        params[:mime_type], params[:url] = Base64.decode64(cd).split('::')
        unless params[:mime_type] && params[:url]
          raise OMF::Web::Rack::MissingArgumentException.new "Can't decode 'content' parameter (#{cd})"
        end
      end
      OMF::Web.deep_symbolize_keys(params)
    end
    
    
    
    def collect_data_sources(ds_set)
      @widgets.each_value do |w|
        w.collect_data_sources(ds_set)
      end
      # @plan_widget.collect_data_sources(ds_set)
      # @prepare_widget.collect_data_sources(ds_set)
      # @execute_widget.collect_data_sources(ds_set)
      ds_set
    end
  end
end
