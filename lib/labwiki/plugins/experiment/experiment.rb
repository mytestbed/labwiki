require 'time'
require 'ruby_parser'
require 'omf_web'
require 'omf-web/content/repository'
require 'omf_oml/table'
require 'labwiki/plugins/experiment/run_exp_controller'
require 'labwiki/plugins/experiment/oml_connector'
require 'labwiki/plugins/experiment/graph_description'
require 'labwiki/plugins/experiment/redis_helper'

# HACK to read data source from data source proxy, this should go to omf_web
module OMF::Web
  class DataSourceProxy < OMF::Common::LObject
    attr_reader :data_source
  end
end

module LabWiki::Plugin::Experiment

  # Maintains the context for a particular experiment.
  #
  class Experiment < OMF::Base::LObject
    include LabWiki::Plugin::Experiment::RedisHelper

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

    def recreate_experiment(omf_exp_id)
      @name = omf_exp_id
      @url = redis.get ns(:url, omf_exp_id)
      @state = redis.get ns(:status, omf_exp_id)
      @start_time = Time.new (redis.get ns(:start_time, omf_exp_id))
      @properties = redis.smembers(ns(:props, omf_exp_id)).map { |p| JSON.parse(p).symbolize_keys }
      create_oml_tables

      pid = redis.get ns(:pid, omf_exp_id)
      @ec = LabWiki::Plugin::Experiment::RunExpController.new(@name) do |etype, msg|
        handle_exp_output @ec, etype, msg
      end
      @ec.monitor(pid)
    end

    def start_experiment(properties, slice, name, irods = {})
      unless @state == :new
        warn "Attempt to start an already running or finished experiment"
        return # TODO: Raise appropriate exception
      end

      @slice = slice
      ts = Time.now.iso8601.split('+')[0].gsub(':', '-')
      @name = "#{self.user}-"
      if (!name.nil? && name.to_s.strip.length > 0)
        @name += "#{name.gsub(/\W+/, '_')}-"
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
      #exp = { id: @name, instance: self }
      exp = { id: @name }

      if irods
        exp[:irods_path] = irods[:path]
        exp[:exp_name] = irods[:exp_name]
      end
      OMF::Web::SessionStore[:exps, :omf] << exp

      create_oml_tables()

      props = {'experiment-id' => @name}
      properties.each { |p| props[p[:name]] = p[:value] }
      @properties.each { |p| p[:value] = props[p[:name]] ||= p[:default] }

      @ec = LabWiki::Plugin::Experiment::RunExpController.new(@name, slice, script, props, @config_opts) do |etype, msg|
        handle_exp_output @ec, etype, msg
      end

      unless @state == :finished
        @start_time = Time.now
        self.persist [:name, :status, :props, :url, :start_time]

        @ec.start
      end
    end

    def stop_experiment()
      @state = :finished
      @ec.stop
      self.persist [:status]
      @oml_connector.disconnect
    end

    def create_oml_tables
      unless (dsp = OMF::Web::DataSourceProxy["status_#{@name}"] && @status_table = dsp.data_source)
        @status_table = OMF::OML::OmlTable.new "status_#{@name}", [[:time, :int], :phase, [:completion, :float], :message]
        OMF::Web::DataSourceProxy.register_datasource @status_table rescue warn $!
      end

      unless (dsp = OMF::Web::DataSourceProxy["log_#{@name}"] && @log_table = dsp.data_source)
        @log_table = OMF::OML::OmlTable.new "log_#{@name}", [[:time, :int], :severity, :path, :message]
        OMF::Web::DataSourceProxy.register_datasource @log_table rescue warn $!
      end

      unless (dsp = OMF::Web::DataSourceProxy["graph_#{@name}"] && @graph_table = dsp.data_source)
        @graph_table = OMF::OML::OmlTable.new "graph_#{@name}", [:id, :description]
        OMF::Web::DataSourceProxy.register_datasource @graph_table rescue warn $!
      end

      @oml_connector = OmlConnector.new(@name, @graph_table, @config_opts[:oml])
    end

    def to_json
    end

    def user
      OMF::Web::SessionStore[:id, :user] || 'unknown'
    end

    # Write internal data to persistent data store, provide an array of keys indicating what to store
    #
    # @param [Array] data_to_store indicate what data to store
    #
    # @example
    #     persist [:name, :status, :props, :url]
    #
    def persist(data_to_store = [:status])
      data_to_store.each do |key|
        case key
        when :status
          redis.set ns(:status, @name), @state
        when :name
          redis.sadd ns(:experiments, user), @name
        when :props
          @properties.each { |p| redis.sadd ns(:props, @name), p.to_json }
        when :url
          redis.set ns(:url, @name), @url
        when :start_time
          redis.set ns(:start_time, @name), @start_time
        when :pid
          redis.set ns(:pid, @name), @ec.pid
        end
      end
    end

    def handle_exp_output(ec, etype, msg)
      begin
        debug "output:#{etype}: #{msg.inspect}"

        case etype
        when 'STARTED'
          info "Experiment #{@name} started. PID: #{ec.pid}"
          @state = :running
          self.persist [:status, :pid]
        when 'LOG'
          process_exp_stdout_msg(msg)
        when 'DONE.OK'
          @state = :finished
          self.persist [:status]
          @oml_connector.disconnect
        end
      rescue Exception => ex
        warn "EXCEPTION: #{ex}"
        debug ex.backtrace.join("\n")
      end
    end

    def process_exp_stdout_msg(msg)
      if (m = msg.match /^.*(INFO|WARN|ERROR|DEBUG|FATAL)\s+(.*)$/)
        severity = m[1].to_sym
        path = ''
        message = m[-1]
        return if message.start_with? '------'

        if (m = message.match(/^\s*REPORT:([A-Za-z:]*)\s*(.*)/))
          case m[1]
          when /START:/
            @gd = LabWiki::Plugin::Experiment::GraphDescription.new
          when /STOP/
            @oml_connector.add_graph(@gd)
            @gd = nil
          else
            @gd.parse(m[1], m[2])
          end
          return
        end

        log_msg_row = [Time.now - @start_time, severity, path, message]
        @log_table.add_row(log_msg_row)
      end
    end

    # As widgets are dynamically added, we need register datasources from within the
    # widget renderer.
    #
    def datasource_renderer
      lp = @log_proxy ||= OMF::Web::DataSourceProxy.for_source(:name => "log_#{@name}")[0]

      gp = @graph_proxy ||= OMF::Web::DataSourceProxy.for_source(:name => "graph_#{@name}")[0]
      #gp.to_javascript(1) + lp.to_javascript(1)
      gp.to_javascript() + lp.to_javascript()
    end

    def parse_oidl_script(content)
      parser = RubyParser.new
      sexp = parser.process(content)
      # Looking for 'defProperty'
      properties = sexp.collect do |sx|
        #puts "SX: >>> #{sx}"
        next if sx.nil? || (sx.is_a? Symbol)
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
