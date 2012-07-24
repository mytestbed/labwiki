require 'time'
require 'ruby_parser'
require 'omf-web/widget/abstract_widget'
require 'omf-web/content/repository'

module LabWiki     
      
  # Maintains the context for a particular experiment in this user context.
  #
  class ExperimentWidget < OMF::Web::Widget::AbstractWidget
    def self.create_for(opts)
      unless url = opts[:url]
        raise "Expected 'url' for experiment script in '#{opts.inspect}'"
      end
      self.new(
        :script => url
      )
    end

    def self.create(opts)
      #opts[:is_new] = true
      self.new(opts)
    end
    
    def self.find(opts)
      unless url = opts[:url]
        raise "Expected 'url' for experiment script in '#{opts.inspect}'"
      end
      raise "Can't handle showing exisiting experiments '#{opts}'"
    end
    
    #attr_reader :exp_properties, :script_path
    
    def initialize(opts)
      opts[:type] = :experiment
      super opts
      @state = :new
      configure(opts)
    end
    
    def configure(opts)
      debug "opts; #{opts.inspect}"
      #@is_new = (opts[:is_new] == true)
      unless properties = opts[:properties]
        if (script = opts[:script])
          description = OMF::Web::ContentRepository.read_content(script, opts)
          opts[:properties] = parse_oidl_script(description)
        end
      end
      if name = opts[:name]
        @title = name
      else
        opts[:name] = "slice-" + Time.now.iso8601
        @title = "NEW"  
      end
      @opts = opts
    end
    
    def start(opts)
      configure(opts)
      @state = :prepare_to_run
    end
    
    def new?
      @state == :new
    end
    
    def content()
      OMF::Web::Theme.require 'experiment_renderer'
      debug "Content: #{opts.inspect}"
      OMF::Web::Theme::ExperimentRenderer.new(self, @opts)
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
    
    def parse_oidl_script(content)
      parser = RubyParser.new
      sexp = parser.process(content)
      # Looking for 'defProperty'
      properties = sexp.collect do |sx|
        next if (sx.is_a? Symbol)
        next unless sx[0] == :call
        next unless sx[2] == :defProperty

        params = sx[3]
        ph = {}
        [nil, :name, :default, :comment].each_with_index do |key, i|
          next unless (v = params[i]).is_a? Sexp
          ph[key] = v[1]
        end
        ph        
      end.compact
      
      debug "parse_oidl_script: #{properties.inspect}"
      properties
    end
    
    
  end # class

end # module