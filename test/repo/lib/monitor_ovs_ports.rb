#
# Monitor the port assignment on a vswitch and report any changes through an 
# OML stream
#

require 'oml4r'

APPNAME = File.basename($0).split('.')[0]


class PortAssignment < OML4R::MPBase
  name :port_assignment

  param :name
  param :port_no, :type => :int32
  param :status # :added, :removed, :active (a periodic heartbeat)
end

#
# This class is essentially the main program. It periodically
# calls '???', extracts information about the exisiting port
# assignments and reports any changes
#
class Runner

  #
  # Initialise this object and OML
  #
  # - args = the command line argument which was given to this wrapper 
  #          application
  #
  def initialize(args)
    @interval = 5
    @testing = false # run 'test' method instead of normal loop on 'start'

    OML4R::init(args, :expID => 'monitor_openflow', :appName => APPNAME) do |ap|
      ap.banner = "\nMonitor OVS's port assignments\n" +
        "Use -h or --help for a list of options\n\n" 
      ap.on("-s", "--sampling DURATION", "Interval in second between sample collection for OML") do |time| 
        @interval = time 
      end
      ap.on(nil, "--testing", "Just send a few test tuples and then return") { @testing = true }
    end
    @interval = @interval.to_i
  end

  #  
  # Start the monitoring proess.
  # NOTE: This does NOT return
  #
  def start()
    if @testing 
      return test
    end

    # Loop until the user interrupts us
    cmd = "/usr/bin/ovs-ofctl  show br-int | grep addr:"
    while true
      output = `cmd`
      process_output(output)
      sleep @interval
    end
  end

  def test()
    s = %{
 1(eth0): addr:00:03:2d:0d:30:d4
 2(gre1): addr:9a:d9:bf:86:dc:fb
 4(wlan1): addr:00:1b:b1:5e:3c:aa
 LOCAL(br-int): addr:00:03:2d:0d:30:d4
}
    process_output(s)
    sleep 1
    process_output(s)
  end

  #
  # Process each output coming from an executing of the "wlaconfig" application
  # - output =  a String holding the output to process
  #
  def process_output(output)
    output.each_line do |l|
      if m = l.match(/\s*([0-9]+)\(([^)]*)/)
        dummy, port_no, port_name = m.to_a
        report_port(port_name, port_no)
      end
    end
  end

  def report_port(name, port_no)
    PortAssignment.inject name, port_no, :added
  end


end

#
# Entry point to this Ruby application
#
begin
  app = Runner.new(ARGV)
  app.start()
rescue SystemExit
rescue SignalException
  puts "Wrapper stopped."
rescue Exception => ex
  puts "Error - Message: #{ex}\n\n"
  # Uncomment the next line to get more info on errors
  puts "Trace - #{ex.backtrace.join("\n\t")}"
end
OML4R::close()
