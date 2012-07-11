
require 'omf-web/widget/abstract_widget'

module LabWiki     
      
  # Maintains the context for a particular experiment in this context.
  #
  class ExperimentWidget < OMF::Web::Widget::AbstractWidget
    def self.create_for(path)
      self.new(
        :source_path => path
      )
    end

    def self.create
      self.new()
    end
    
    def self.find(path)
      raise "Can't handle showing exisiting experiments '#{path}'"
    end
    
    
    def initialize(opts)
      opts[:type] = :experiment
      super opts
      
      if @path = opts[:path]
        @title = "Should know"
      else
        @title = "NEW (#{opts[:source_path]})"  
      end
      
    end
    
    def content()
      OMF::Web::Theme.require 'experiment_renderer'
      OMF::Web::Theme::ExperimentRenderer.new(self, {}, @opts)
    end
    
    def mime_type
      'experiment'
    end

    def title
      @title
    end    
    
    def collect_data_sources(ds_set)
      ds_set
    end
    
    
  end # class

end # module