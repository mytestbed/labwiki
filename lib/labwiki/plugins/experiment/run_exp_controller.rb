
require 'fcntl'
require 'omf_base/lobject'

module LabWiki
  module Plugin
    module Experiment
    end
  end
end


module LabWiki::Plugin::Experiment
  #
  # Run an experiment controller in the background.
  #
  # Borrows from Open3
  #
  class RunExpController < OMF::Base::LObject
    
    #RUN_CMD = '~/src/omf_labwiki/test/omf_exec/omf_exec-norbit.sh'
  
    # Holds the pids for all active apps
    @@apps = Hash.new
  
    # True if this active app is being killed by a proper
    # call to ExecApp.killAll() or kill()
    # (i.e. when the caller of ExecApp decided to stop the application,
    # as far as we are concerned, this is a 'clean' exit)
    @cleanExit = false
  
    def self.[](id)
      app = @@apps[id]
      if (app == nil)
        warn "Unknown experiment '#{id}/#{id.class}'"
      end
      return app
    end
  
    def self.kill_all(signal = 'KILL')
      @@apps.each_value { |app|
        app.kill(signal)
      }
    end
  
    def stdin(line)
      debug "writing '#{line}' to experiment '#{@id}'"
      @stdin.write("#{line}\n")
      @stdin.flush
    end
  
    def kill(signal = 'KILL')
      @cleanExit = true
      Process.kill(signal, @pid)
    end
    
    def stop()
      kill("-INT")
    end
  
    #
    # Run an experiment controller 'cmd' in a separate thread and monitor
    # its stdout. Also send status reports to the provided block which should
    # have two arguments, eventType and message.
    #
    # @param id ID of application (used for reporting)
    # @param slice Name of slice
    # @param exp_script Name of OIDL script
    # @param properties Hahs of properties to pass to experiment
    # @param config_opts - Configuration option, need to contain 'ec_runner'
    #
    def initialize(id, slice, exp_script, properties, config_opts, &block)
  
      @id = id
      @observer = block
      @@apps[id] = self
      @running = true
      
      script_props = []
      if exp_id = properties.delete('experiment-id')
        script_props << "--experiment-id #{exp_id}"
      end
      if slice && !slice.empty?
        script_props << "--slice #{slice}"
      end

      props = properties.map { |k, v| "--#{k} '#{v}'" }

      unless ec_runner = config_opts[:ec_runner]
        raise "Missing 'ec_runner' declaration in experiment configuration"
      end
      #cmd = "#{RUN_CMD} #{exp_script} #{script_props.join(' ')} -- #{props.join(' ')}" 
      cmd = "#{ec_runner} #{exp_script} #{script_props.join(' ')} -- #{props.join(' ')}" 
      debug "CMD: #{cmd}"
      
      pw = IO::pipe   # pipe[0] for read, pipe[1] for write
      pr = IO::pipe
      pe = IO::pipe
  
      debug "Starting application '#{id}' - cmd: '#{cmd}'"
      @observer.call('STARTED', nil)
      @pid = fork do
        Process.setpgid(0,Process.pid)
        # child will remap pipes to std and exec cmd
        pw[1].close
        STDIN.reopen(pw[0])
        pw[0].close
  
        pr[0].close
        STDOUT.reopen(pr[1])
        pr[1].close
  
        pe[0].close
        STDERR.reopen(pe[1])
        pe[1].close
  
        begin
          exec(cmd)
        rescue => ex
          if cmd.kind_of?(Array)
            cmd = cmd.join(' ')
          end
          STDERR.puts "exec failed for '#{cmd}'(#{$!}): #{ex}"
        end
        # Should never get here
        exit!
      end
  
      pw[0].close
      pr[1].close
      pe[1].close
      @pipes = [pr[0], pe[0], pw[1]]
      @stdin = pw[1]

      @threads = []
      @threads << monitor_pipe('STDOUT', pr[0])
      @threads << monitor_pipe('STDERR', pe[0])
      monitor_exit()
    end
    
    #
    # Create a thread to monitor the process and its output
    # and report that back to the server
    #
    # @parma name Name of app stream to monitor (should be stdout, stderr)
    # @param pipe Pipe to read from
    #
    def monitor_pipe(name, pipe)
      Thread.new() do
        begin
          while @running do
            msg = pipe.readline.chomp
            @observer.call(name, msg)
          end
        rescue EOFError
          # do nothing
        rescue Exception => err
          error "monitorApp(#{@id}): #{err}"
        ensure
  #        debug "#{@id} IO close"
          pipe.close
        end
        debug "Thread #{name} finished"
      end
    end
    
    def monitor_exit
      # Create thread which waits for application to exit
      Thread.new(@id, @pid) do |id, pid|
        ret = Process.waitpid(pid)
        status = $?
        @@apps.delete(id)
        @running = false
        # app finished
        if (status == 0) || @cleanExit
          s = "OK"
          info "Experiment '#{id}' finished"
        else
          s = "ERROR"
          error "Experiment '#{id}' failed (code=#{status})"
        end
        # begin
          # @threads.each {|t| Thread.kill(t) }
        # rescue Exception => err
          # error "monitor_exit(#{id}): #{err}"
        # end        
        @observer.call("DONE.#{s}", "status: #{status}")
      end
    end
    
  
  end # class
end # module LabWiki::Plugin::Experiment

if $0 == __FILE__
  OMF::Base::Loggable.init_log 'run_exec_test'
  require 'labwiki/plugins/experiment/graph_description'
  LabWiki::Plugin::Experiment::GraphDescription.new
    

  #cmd = '~/src/omf_labwiki/test/omf_exec/omf_exec-norbit.sh ~/src/omf_labwiki/test/repo/oidl/tutorial/using-properties.rb -- --res1 omf.nicta.node11 --res2 omf.nicta.node12'
  script = '~/src/omf_labwiki/test/repo/oidl/tutorial/using-properties.rb'
  properties = {:res1 => 'omf.nicta.node11', :res2 => 'omf.nicta.node12'}
  ec = LabWiki::Plugin::Experiment::RunExpController.new(:test, script, properties) do |etype, message|
    begin
      puts "<<#{etype}>> <#{message.inspect}>"
      
      if etype == 'STDOUT'
        if m = message.match(/^\s*([A-Z]+)\s*([^:]*):\s*(.*)/)
          # ' INFO NodeHandler: OMF Experiment..' => ['...'. 'INFO', 'NodeHandler', 'OMF ...']
          msg = {:type => m[1].to_sym, :module => m[2], :message => m[3]}
          if msg[:module] == 'GraphDescription' && (m = msg[:message].match(/^\s*REPORT:([A-Za-z:]*)\s*(.*)/))
            if m[1] == 'START:'
              gd = Thread.current['__xxx__'] = LabWiki::Plugin::Experiment::GraphDescription.new
            else
              gd = Thread.current['__xxx__']
            end
            gd.parse(m[1], m[2])
            if m[1] == 'STOP'
              puts "GG>>> #{gd.inspect}"
            end
            
          end
        end
      end
    rescue Exception => ex
      puts "EXCEPTION: #{ex}"
    end
    
    if etype == 'DONE.OK'
      Thread.list.each {|t| p t}
      sleep 5
      exit
    end
  end

  sleep 2000
end

