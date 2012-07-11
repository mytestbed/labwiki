
require 'labwiki/column_widget'
require 'labwiki/theme/col_content_renderer'

require 'labwiki/experiment_widget'

module LabWiki    
  
  # Responsible for the PLAN column
  # Only shows formated text 
  #
  class ExecuteWidget < ColumnWidget
    
    def on_get(opts, req)
      super
      path = opts[:path]
      
      # TODO: The following has the notion of EXPERIMENT pretty much hard coded.
      if opts[:mime_type].start_with? 'text'
        # new experiment
        @embedded_widget = ExperimentWidget.create_for(path)
      elsif path
        @embedded_widget = ExperimentWidget.find(path)
      elsif opts[:create] == true
        case opts[:mime_type]
        when 'experiment'
          @embedded_widget = ExperimentWidget.create()
        else
          raise "Don't know how to create '#{opts[:mime_type]}'"
        end     
      else
        raise "Don't know what to do"
      end     

      r = OMF::Web::Theme::ColumnContentRenderer.new(self, @embedded_widget, @name)
      [r.to_html, "text/html"]
    end
    
  end
end
