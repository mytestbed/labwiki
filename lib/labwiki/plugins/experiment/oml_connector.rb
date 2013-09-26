require 'eventmachine'
require 'em-synchrony'
require 'sequel'
require 'em-pg-sequel'
require 'monitor'

module LabWiki::Plugin::Experiment
  # Establishes a connection to the database associated with a
  # single experiment.
  #
  class OmlConnector < OMF::Base::LObject
    include MonitorMixin

    def initialize(exp_id, graph_table, config_opts)
      super()
      @exp_id = exp_id
      @graph_table = graph_table
      @config_opts = config_opts
      @graph_descriptions = []
      @connected = false
      @periodic_timers = {}

      EM.synchrony do
        _connect(exp_id)
      end
    end

    def disconnect
      debug "Disconnecting #{@exp_id}...#{@connection}"
      if connected?
        @connection.disconnect
        info "#{@exp_id} DB DISCONNECED ...#{@connection}"

        synchronize do
          @connected = false
        end
      end
      # Cancel timers
      synchronize do
        @periodic_timers.each do |k, v|
          v.cancel
        end
        @periodic_timers.clear
      end
    end

    def connected?
      @connected
    end

    def add_graph(graph_descr)
      debug "Received graph description '#{graph_descr}'"
      h = { :graph_descr => graph_descr, :processed => false }
      @graph_descriptions << h
      _init_graph(h) if connected?
    end

    def _init_graph(gd)
      synchronize do
        return if gd[:processed]
        gd[:processed] = true
      end

      gd[:graph_descr].mstreams.each do |name, sql|
        _init_mstream(name, sql, gd)
      end
    end

    def _init_mstream(name, sql, gd)
      debug "Initializing mstream '#{name}' (#{sql})"

      if sql =~ /SELECT (.+) FROM \"(.+)\"/
        select_str = $1.dup
        db_table_name = $2.dup.to_sym

        db_fields = {}.tap do |f_hash|
          select_str.split(", ").each do |f|
            if f =~ /\"(.+)\" AS \"(.+)\"/
              f_hash[$1.to_sym] = $2.to_sym
            elsif f =~ /\"(.+)\"/
              f_hash[$1.to_sym] = nil
            end
          end
        end
      end

      table = nil

      t_describe_table = EM::Synchrony.add_periodic_timer(5) do
        schema = @connection.schema(db_table_name).map do |col, meta|
          if db_fields.keys.include?(col)
            if db_fields[col].nil?
              [col, meta[:type]]
            else
              [db_fields[col], meta[:type]]
            end
          end
        end.compact
        debug "Schema >> #{schema}"
        tname = "#{gd[:graph_descr].name}_#{name}_#{@exp_id}"
        table = OMF::OML::OmlTable.new tname, schema
        debug "Created table '#{table.inspect}'"
        OMF::Web::DataSourceProxy.register_datasource table

        gopts = gd[:graph_descr].render_option()
        # TODO: Locks us into graphs with single data sources
        gopts[:data_sources] = [{
          :name => tname,
          :stream => tname, # not sure what we need this for?
          :schema => table.schema,
          :update_interval => 1
        }]
        @graph_table.add_row [table.object_id, gopts.to_json]
        t_describe_table.cancel
      end

      synchronize do
        @periodic_timers[:describe] = t_describe_table
      end

      limit = 20
      offset = 0
      dataset = nil
      t_query = EM::Synchrony.add_periodic_timer(5) do
        if table
          if dataset
            unless (rows = dataset.all).empty?
              debug "Found rows >> #{rows.inspect}"
              rows = rows.map { |v| v.values }
              table.add_rows rows, true
              offset += rows.length
            end
          end
          begin
            dataset = @connection.fetch("#{sql} LIMIT #{limit} OFFSET #{offset}")
          rescue => e
            warn "Exception while running query '#{sql}' - #{e}"
            dataset = nil
          end
        end
      end
      synchronize do
        @periodic_timers[:query] = t_query
      end
    end

    def _connect(exp_id)
      db_uri = "postgres://#{@config_opts[:user]}:#{@config_opts[:pwd]}@#{@config_opts[:host]}/#{exp_id}"
      info "Attempting to connect to OML backend (DB) on '#{db_uri}' - #{object_id}-#{Thread.current}"

      t_connect = EM::Synchrony.add_periodic_timer(10) do
        begin
          connection = Sequel.connect(db_uri, pool_class: EM::PG::ConnectionPool, max_connections: 2)
          _on_connected(connection)

          t_connect.cancel # Connected
        rescue => e
          if e.message =~ /PG::Error: FATAL:  database .+ does not exist/
            debug "Database '#{exp_id}' doesn't exist yet"
          else
            error "Connection to OML backend (DB) failed - #{e}"
            debug e.backtrace.join("\n\t")
            t_connect.cancel # DB server says no
          end
        end
      end

      synchronize do
        @periodic_timers[:connect] = t_connect
      end
    end

    def _on_connected(connection)
      synchronize do
        @connection = connection
        @connected = true
      end
      debug "Connected to OML backend '#{@exp_id}' - #{@graph_descriptions.inspect}"
      @graph_descriptions.each do |gd|
        _init_graph(gd)
      end
    end
  end # class
end # module


