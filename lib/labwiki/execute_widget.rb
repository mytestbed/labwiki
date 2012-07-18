
require 'labwiki/column_widget'
require 'labwiki/theme/col_content_renderer'

require 'labwiki/experiment_widget'

module LabWiki    
  
  # Responsible for the PLAN column
  # Only shows formated text 
  #
  class ExecuteWidget < ColumnWidget
    
    def on_get_content(params, req)
      p = parse_req_params(params, req)
      path = p[:path]
      debug "on_get_content: '#{params.inspect}'"
      
      # TODO: The following has the notion of EXPERIMENT pretty much hard coded.
      if p[:mime_type].start_with? 'text'
        # new experiment
        embedded_widget = ExperimentWidget.create_for(path)
      elsif path
        embedded_widget = ExperimentWidget.find(path)
      else
        raise "Don't know what to do"
      end     

      r = OMF::Web::Theme::ColumnContentRenderer.new(self, embedded_widget, @name)
      [r.to_html, "text/html"]
    end
    
    def on_get_create(params, req)
      p = parse_req_params(params, req)
      path = p[:path]
      debug "on_get_create: '#{params.inspect}'"
      
      # TODO: The following has the notion of EXPERIMENT pretty much hard coded.
      case @mime_type
      when 'experiment'
        embedded_widget = ExperimentWidget.create()
      else
        raise "Don't know how to create '#{@mime_type}'"
      end     

      r = OMF::Web::Theme::ColumnContentRenderer.new(self, embedded_widget, @name)
      [r.to_html, "text/html"]
    end
    
    def on_start_experiment(params, req)
      debug "on_start_experiment: '#{params.inspect}'"
      embedded_widget = ExperimentWidget.create(params)

      r = OMF::Web::Theme::ColumnContentRenderer.new(self, embedded_widget, @name)
      [r.to_html, "text/html"]
      
    end
  end
end
