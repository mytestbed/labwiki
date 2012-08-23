require 'time'
require 'ruby_parser'
require 'labwiki/column_widget'
require 'omf-web/content/repository'

module LabWiki     
      
  # Maintains the context for a particular experiment in this user context.
  #
  class ExperimentWidget < LabWiki::ColumnWidget
    # def self.create_for(opts)
      # unless url = opts[:url]
        # raise "Expected 'url' for experiment script in '#{opts.inspect}'"
      # end
      # self.new(
        # :script => url
      # )
    # end
# 
    # def self.create(opts)
      # #opts[:is_new] = true
      # self.new(opts)
    # end
#     
    # def self.find(opts)
      # unless url = opts[:url]
        # raise "Expected 'url' for experiment script in '#{opts.inspect}'"
      # end
      # raise "Can't handle showing exisiting experiments '#{opts}'"
    # end
    
    #attr_reader :exp_properties, :script_path
    
    def initialize(column, unused)
      unless column == :execute
        raise "Should only be used in 'execute' column"
      end
      super column, :type => :experiment
      @state = :new
    end
    
    def on_get_content(params, req)      
      debug "on_get_content: '#{params.inspect}'"
      
      unless properties = @opts[:properties]
        if (url = @opts[:url] = params[:url])
          description = OMF::Web::ContentRepository.read_content(url, {})
          @opts[:properties] = parse_oidl_script(description)
        end
      end
      @opts[:name] = "slice-" + Time.now.iso8601
      @title = "NEW"  
    end
    
    def on_start_experiment(params, req)
      @state = :prepare_to_run
      if name = params[:name]
        @title = @opts[:name] = name
      end
      # Set all unassigned properties to their default value
      @opts[:properties].each do |prop|
        prop[:value] ||= prop[:default]
      end
    end
    
    # def start(opts)
      # configure(opts)
      # @state = :prepare_to_run
    # end
    
    def new?
      @state == :new
    end
    
    def content_renderer()
      OMF::Web::Theme.require 'experiment_renderer'
      debug "content_renderer: #{@opts.inspect}"
      OMF::Web::Theme::ExperimentRenderer.new(self, @opts)
    end
    
    def mime_type
      'experiment'
    end

    def title
      @title
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