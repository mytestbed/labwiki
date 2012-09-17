require 'time'
require 'ruby_parser'
require 'labwiki/column_widget'
require 'omf_web'
require 'omf-web/content/repository'
require 'omf-oml/table'
require 'labwiki/plugins/experiment/run_exp_controller'
require 'labwiki/plugins/experiment/graph_description'
require 'labwiki/plugins/experiment/oml_connector'

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
      @state = :new
      ts = Time.now.iso8601.split('+')[0].gsub(':', '-')
      @opts[:name] = @name = "exp-" + ts
      @content_url = "exp:#{@name}"
      @graph_descriptions = []
    end
    
    def on_get_content(params, req)      
      debug "on_get_content: '#{params.inspect}'"
      
      unless properties = @opts[:properties]
        if (url = @opts[:url] = params[:url])
          description = OMF::Web::ContentRepository.read_content(url, {})
          @opts[:properties] = parse_oidl_script(description)
        end
      end
      @title = "NEW"  
    end
    
    def on_start_experiment(params, req)
      unless @state == :new
        warn "Attempt to start an already running or finished experiment"
        return # TODO: Raise appropriate exception
      end
      
      @title = @name
      debug "on_start: opts: #{@opts.inspect}"
      url = @opts[:url]
      unless script = OMF::Web::ContentRepository.absolute_path_for(url)
        warn "Can't find script '#{url}'"
        return # TODO: Raise appropriate exception
      end

      # Set all unassigned properties to their default value
      @opts[:properties].each do |prop|
        prop[:value] ||= prop[:default]
      end

      @status_ds_name = "status_#{@name}"
      @status_table = OMF::OML::OmlTable.new @status_ds_name, [[:time, :int], :phase, [:completion, :float], :message]
      OMF::Web::DataSourceProxy.register_datasource @status_table

      @log_ds_name = "log_#{@name}"
      @log_table = OMF::OML::OmlTable.new @log_ds_name, [[:time, :int], :severity, :path, :message]
      OMF::Web::DataSourceProxy.register_datasource @log_table
      
      @graph_ds_name = "graph_#{@name}"
      @graph_table = OMF::OML::OmlTable.new @graph_ds_name, [:id, :description]
      OMF::Web::DataSourceProxy.register_datasource @graph_table
      @oml_connector = OmlConnector.new(@name, @graph_table)
      
      props = {'experiment-id' => @name}
      @opts[:properties].each { |p| props[p[:name]] = p[:value] }
      @state = :running
      @start_time = Time.now
      @ec = LabWiki::Plugin::Experiment::RunExpController.new(@name, script, props) do |etype, msg|
        handle_exp_output @ec, etype, msg
      end
    end
    
    def handle_exp_output(ec, etype, msg)
      begin
        debug "output:#{etype}: #{msg.inspect}"
        
        if etype == 'STDOUT'
          if m = msg.match(/^\s*([A-Z]+)\s*([^:]*):\s*(.*)/)
            # ' INFO NodeHandler: OMF Experiment..' => ['...'. 'INFO', 'NodeHandler', 'OMF ...']
            severity = m[1].to_sym
            path = m[2]
            message = m[3]
            return if message.start_with? '------'
                        
            if path == 'GraphDescription' && (m = message.match(/^\s*REPORT:([A-Za-z:]*)\s*(.*)/))
              if m[1] == 'START:'
                @gd = LabWiki::Plugin::Experiment::GraphDescription.new
              end
              @gd.parse(m[1], m[2])
              if m[1] == 'STOP'
                @oml_connector.add_graph(@gd)
                # @graph_descriptions << @gd
                # @graph_table.add_row [@gd.object_id, @gd.render_description().to_json]
                @gd = nil
              end
              return
            end

            @log_table.add_row [Time.now - @start_time, severity, path, message]
          end
        end
      rescue Exception => ex
        warn "EXCEPTION: #{ex}"
      end
      
      if etype == 'DONE.OK'
        @state = :finished
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
      debug "content_renderer: #{@opts.inspect}"
      if @state == :new
        OMF::Web::Theme.require 'experiment_setup_renderer'
        ExperimentSetupRenderer.new(self, @opts)
      else
        OMF::Web::Theme.require 'experiment_running_renderer'
        ExperimentRunningRenderer.new(self, @opts)
      end
        
    end
    
    # As widget are dynamically added, we need register datasources from within the 
    # widget renderer.
    #
    def datasource_renderer
      lp = @log_proxy ||= OMF::Web::DataSourceProxy.for_source(:name => @log_ds_name)[0]      
      gp = @graph_proxy ||= OMF::Web::DataSourceProxy.for_source(:name => @graph_ds_name)[0]
      gp.to_javascript(1) + lp.to_javascript(1)
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