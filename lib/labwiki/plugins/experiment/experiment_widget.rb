require 'labwiki/column_widget'
require 'labwiki/plugins/experiment/run_exp_controller'
require 'labwiki/plugins/experiment/experiment'

module LabWiki::Plugin::Experiment
        
  # Maintains the context for a particular experiment in this user context.
  #
  class ExperimentWidget < LabWiki::ColumnWidget

    attr_reader :name
    
    def initialize(column, unused)
      unless column == :execute
        raise "Should only be used in 'execute' column"
      end
      super column, :type => :experiment
      @experiment = nil
    end
    
    def on_get_content(params, req)      
      debug "on_get_content: '#{params.inspect}'"
      
      if @experiment
        # release currenlty used experiment
      end
      
      @experiment = LabWiki::Plugin::Experiment::Experiment.new
      if (url = params[:url])
        @experiment.script = url
      end
      @title = "NEW"  
    end
    
    def on_start_experiment(params, req)
      @experiment.start_experiment
    end
    
    def on_stop_experiment(params, req)
      @experiment.stop_experiment
    end

    def new?
      @experiment ? (@experiment.state == :new) : false
    end
    
    def content_renderer()
      debug "content_renderer: #{@opts.inspect}"
      if new?
        OMF::Web::Theme.require 'experiment_setup_renderer'
        ExperimentSetupRenderer.new(self, @experiment)
      else
        OMF::Web::Theme.require 'experiment_running_renderer'
        ExperimentRunningRenderer.new(self, @experiment)
      end
        
    end
        
    def mime_type
      'experiment'
    end

    def title
      @experiment ? (@experiment.name || 'NEW') : 'No Experiment'
    end        
    
  end # class

end # module