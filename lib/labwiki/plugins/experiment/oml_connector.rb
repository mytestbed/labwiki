
require 'postgres-pr/connection'
#require 'sequel'
require 'monitor'
#require 'em-postgresql-sequel'
#require 'postgres_connection'
      
module LabWiki::Plugin::Experiment
        
  # Establishes a connection to the database associated with a 
  # single experiment.
  #
  class OmlConnector < OMF::Common::LObject
        
    TOID2TYPE = {
      17 => :blob,
      20 => :integer,
      21 => :integer,
      23 => :integer,
      25 => :string,
      700 => :float,
      701 => :float,
      1700 => :integer,
    }

    TYPE_OID = {
      16 => :bool,
      17 => :bytea,
      18 => :char,
      19 => :name,
      20 => :int8,
      21 => :int2,
      22 => :int2vector,
      23 => :int4,
      24 => :regproc,
      25 => :text,
      26 => :oid,
      27 => :tid,
      28 => :xid,
      29 => :cid,
      30 => :oidvector,
      114 => :json,
      142 => :xml,
      194 => :pgnodetree,
      600 => :point,
      601 => :lseg,
      602 => :path,
      603 => :box,
      604 => :polygon,
      628 => :line,
      700 => :float4,
      701 => :float8,
      702 => :abstime,
      703 => :reltime,
      704 => :tinterval,
      705 => :unknown,
      718 => :circle,
      790 => :cash,
      829 => :macaddr,
      869 => :inet,
      650 => :cidr,
      1007 => :int4array,
      1009 => :textarray,
      1021 => :float4array,
      1033 => :aclitem,
      1263 => :cstringarray,
      1042 => :bpchar,
      1043 => :varchar,
      1082 => :date,
      1083 => :time,
      1114 => :timestamp,
      1184 => :timestamptz,
      1186 => :interval,
      1266 => :timetz,
      1560 => :bit,
      1562 => :varbit,
      1700 => :numeric,
      1790 => :refcursor,
      2202 => :regprocedure,
      2203 => :regoper,
      2204 => :regoperator,
      2205 => :regclass,
      2206 => :regtype,
      2211 => :regtypearray,
      3614 => :tsvector,
      3642 => :gtsvector,
      3615 => :tsquery,
      3734 => :regconfig,
      3769 => :regdictionary,
      3904 => :int4range,
      2249 => :record,
      2287 => :recordarray,
      2275 => :cstring,
      2276 => :any,
      2277 => :anyarray,
      2278 => :void,
      2279 => :trigger,
      3838 => :evttrigger,
      2280 => :language_handler,
      2281 => :internal,
      2282 => :opaque,
      2283 => :anyelement,
      2776 => :anynonarray,
      3500 => :anyenum,
      3115 => :fdw_handler,
      3831 => :anyrange
    }

    def initialize(exp_id, graph_table, config_opts)
      @exp_id = exp_id
      @graph_table = graph_table
      @config_opts = config_opts
      
      @graph_descriptions = []
      @connected = false
      @lock = Monitor.new
      @session_id = Thread.current["sessionID"]
      
      _connect(exp_id)
    end
    
    def add_graph(graph_descr)
      debug "Received graph description '#{graph_descr}'"
      h = {:graph_descr => graph_descr, :processed => false}
      @graph_descriptions << h
      _init_graph(h) if connected? 
    end
    
    def connected?
      unless @connected
        @lock.synchronize do
          @connected = !@connection.nil?
        end
      end
      @connected
    end
    
    def _init_graph(gd)
      @lock.synchronize do
        return if gd[:processed]
        gd[:processed] = true
      end
            
      gd[:graph_descr].mstreams.each do |name, sql|
        _init_mstream(name, sql, gd)
      end
    end

    def _init_mstream(name, sql, gd)
      debug "Initializing mstream '#{name}' (#{sql})"
      
      f = Fiber.new do
        limit = 20
        offset = 0

        a = nil
        loop do
          begin 
            a = @connection.query("#{sql} LIMIT #{limit} OFFSET #{offset}")
            break # Everything setup
          rescue Exception => ex
            msg = ex.message.split("\t")
            if msg[1] == "C42P01"
              debug msg[2]
            else 
              warn "Querying OML backend failed (#{msg[1]}) - #{ex}"
            end
            Fiber.yield # try again later
          end
        end
        schema = a.fields.map do |f|
          unless type = TOID2TYPE[f.type_oid]
            error "Found unknown type_oid '#{TYPE_OID[f.type_oid]} in OML query '#{sql}'"
            return
          end
          [f.name, type]
        end
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
        
        # @lock.synchronize do
          # Thread.current["sessionID"] = @session_id # so the ds_proxy end up in the right session store
          # (gd[:ds_proxies] ||= []) << OMF::Web::DataSourceProxy.for_source(:name => tname)[0]
          # (gd[:table_names] ||= []) << tname
        # end 
                
        loop do
          if a
            unless (rows = a.rows).empty?
              puts ">> #{rows.inspect}"
              table.add_rows rows, true
              offset += rows.length
            end
          end
          Fiber.yield
          begin
            a = @connection.query("#{sql} LIMIT #{limit} OFFSET #{offset}")
          rescue Exception => ex
            warn "Exception while running query '#{sql}' - #{ex}"
            a = nil
          end
        end
      end
      @lock.synchronize do
        (gd[:fibers] ||= []) << f
      end
    end 
    
    
    def _connect(exp_id)
      EM::defer do
        Fiber.new do
          while @connection.nil?
            begin
              sleep 2
              
              db_uri = "tcp://#{@config_opts[:host]}"
              debug "Attempting to connect to OML backend on '#{db_uri}' - #{object_id}-#{Thread.current}"
              conn = PostgresPR::Connection.new(exp_id, @config_opts[:user], @config_opts[:pwd], db_uri)              
              _on_connected(conn)
            rescue Exception => ex
              msg = ex.message.split("\t")
              if msg[1] == "C3D000"
                debug "Database '#{exp_id}' doesn't exist yet"
              else 
                warn "Connection to OML backend failed - #{ex}"
                debug ex.backtrace.join("\n\t")
              end
              sleep 3
            end 
          end
        end.resume
      end
    end    

    def _on_connected(connection)
      @lock.synchronize do
        @connection = connection
      end
      debug "Connected to OML backend '#{@exp_id}' - #{@graph_descriptions.inspect}" 
      @graph_descriptions.each do |gd|
        _init_graph(gd)
      end 
      
      debug "Periodically updating data tables"
      while (true)
        @graph_descriptions.each do |gd|
          gd[:fibers].each {|f| f.resume}
        end
        sleep 3
      end
    end
  end # class
end # module
          

