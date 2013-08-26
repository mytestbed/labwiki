require 'time'
require 'ruby_parser'
require 'omf_web'
require 'omf-web/content/repository'
require 'omf_oml/table'
require 'labwiki/plugins/experiment/run_exp_controller'
require 'labwiki/plugins/experiment/oml_connector'
require 'labwiki/plugins/experiment/graph_description'

module LabWiki::Plugin::Experiment

  # Maintains the context for a particular experiment.
  #
  class Experiment < OMF::Common::LObject

    attr_reader :name, :state, :url, :slice, :properties

    def initialize(description_url = nil, config_opts)
      unless description_url
        @state = :new
        @graph_descriptions = []
      end
      @config_opts = config_opts
    end

    def script=(url)
      if (@url = url)
        description = OMF::Web::ContentRepository.read_content(url, {})
        @properties = parse_oidl_script(description)
      end
    end

    def start_experiment(properties, slice, name, iticket = {})
      unless @state == :new
        warn "Attempt to start an already running or finished experiment"
        return # TODO: Raise appropriate exception
      end

      @slice = slice
      ts = Time.now.iso8601.split('+')[0].gsub(':', '-')
      @name = (OMF::Web::SessionStore[:name, :user] || 'unknown') + '-'
      if (!name.nil? && name.to_s.strip.length > 0)
        @name += "#{name}-"
      end
      @name +=  ts
      @name.delete(' ')
      @content_url = "exp:#{@name}"
      url = @url
      unless script = OMF::Web::ContentRepository.absolute_path_for(url)
        warn "Can't find script '#{url}'"
        return # TODO: Raise appropriate exception
      end
      info "Starting experiment name:#{@name} url: #{url} script: #{script}"

      OMF::Web::SessionStore[:exps, :omf] ||= []
      exp = { id: @name, instance: self }
      if iticket
        exp[:irods_token] = iticket['token']
        exp[:irods_path] = iticket['path']
        exp[:exp_name] = iticket['exp_name']
      end
      OMF::Web::SessionStore[:exps, :omf] << exp

      create_oml_tables()

      props = {'experiment-id' => @name}
      properties.each { |p| props[p[:name]] = p[:value] }
      @properties.each { |p| p[:value] = props[p[:name]] ||= p[:default] }

      unless @state == :finished
        @state = :running
        @start_time = Time.now
        @ec = LabWiki::Plugin::Experiment::RunExpController.new(@name, slice, script, props, @config_opts) do |etype, msg|
          handle_exp_output @ec, etype, msg
        end
      end
    end

    def stop_experiment()
      @state = :finished
      @ec.stop
      @oml_connector.disconnect
    end


    def create_oml_tables
      @status_ds_name = "status_#{@name}"
      @status_table = OMF::OML::OmlTable.new @status_ds_name, [[:time, :int], :phase, [:completion, :float], :message]
      OMF::Web::DataSourceProxy.register_datasource @status_table

      @log_ds_name = "log_#{@name}"
      @log_table = OMF::OML::OmlTable.new @log_ds_name, [[:time, :int], :severity, :path, :message]
      OMF::Web::DataSourceProxy.register_datasource @log_table

      @graph_ds_name = "graph_#{@name}"
      @graph_table = OMF::OML::OmlTable.new @graph_ds_name, [:id, :description]
      OMF::Web::DataSourceProxy.register_datasource @graph_table
      @oml_connector = OmlConnector.new(@name, @graph_table, @config_opts[:oml])
    end

    def to_json

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
        @oml_connector.disconnect
      end
    end

    # As widgets are dynamically added, we need register datasources from within the
    # widget renderer.
    #
    def datasource_renderer
      lp = @log_proxy ||= OMF::Web::DataSourceProxy.for_source(:name => @log_ds_name)[0]
      gp = @graph_proxy ||= OMF::Web::DataSourceProxy.for_source(:name => @graph_ds_name)[0]
      #gp.to_javascript(1) + lp.to_javascript(1)
      gp.to_javascript() + lp.to_javascript()
    end

    def parse_oidl_script(content)
      parser = RubyParser.new
      sexp = parser.process(content)
      # Looking for 'defProperty'
      properties = sexp.collect do |sx|
        #puts "SX: >>> #{sx}"
        next if (sx.is_a? Symbol)
        next unless sx[0] == :call
        next unless sx[2] == :defProperty

        params = sx[3]
        #puts "PARSE: #{params}--#{sx}"
        #next unless params.is_a? Hash
        ph = {}
        [nil, :name, :default, :comment].each_with_index do |key, i|
          next unless (v = params[i]).is_a? Sexp
          ph[key] = v[1]
        end
        if ph.empty?
          warn "Wrong RubyParser version"
          ph = nil
        end
        ph
      end.compact

      debug "parse_oidl_script: #{properties.inspect}"
      properties
    end


  end # class

end # module
