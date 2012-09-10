
require 'labwiki/column_widget'
require 'labwiki/theme/col_content_renderer'

require 'labwiki/plugin'

module LabWiki    
  
  # Responsible for the PLAN column
  # Only shows formated text 
  #
  class ExecuteWidget < ColumnWidget
    
    def on_get_content(params, req)
      p = parse_req_params(params, req)
      path = p[:path]
      debug "on_get_content: '#{p.inspect}'"
      
      @embedded_widget = Plugin.create_execute_widget(p)
      # # TODO: The following has the notion of EXPERIMENT pretty much hard coded.
      # if p[:mime_type].start_with? 'text'
        # # new experiment
        # @embedded_widget = ExperimentWidget.create_for(p)
      # elsif path
        # @embedded_widget = ExperimentWidget.find(p)
      # else
        # raise "Don't know what to do"
      # end     

      r = OMF::Web::Theme::ColumnContentRenderer.new(self, embedded_widget, @name)
      [r.to_html, "text/html"]
    end
    
    def on_get_create(params, req)
      p = parse_req_params(params, req)
      debug "on_get_create: '#{p.inspect}'"
      
      # TODO: The following has the notion of EXPERIMENT pretty much hard coded.
      case @mime_type
      when 'experiment'
        @embedded_widget = ExperimentWidget.create()
      else
        raise "Don't know how to create '#{@mime_type}'"
      end     

      r = OMF::Web::Theme::ColumnContentRenderer.new(self, embedded_widget, @name)
      [r.to_html, "text/html"]
    end
    
    def on_start_experiment(params, req)
      raise ">>>> TEST"
      unless @embedded_widget.is_a? ExperimentWidget
        warn "Request to start experiment which isn't related to last execute request"
        @embedded_widget = ExperimentWidget.create()
      end
      if properties = params[:properties]
        # POST will convert array into hash with integer keys
        params[:properties] = properties.map do |k, v|
          v[:index] = k.to_s.to_i
          v
        end.sort do |a, b|
          a[:index] <=> b[:index]
        end
      end
      debug "on_start_experiment: '#{params.inspect}'"
      @embedded_widget.start(params)

      r = OMF::Web::Theme::ColumnContentRenderer.new(self, @embedded_widget, @name)
      [r.to_html, "text/html"]
      
    end
  end
end
