essid = (0...8).map{65.+(rand(25)).chr}.join
channel = rand(11)+1

defGroup('Sender', "nodeX-Y.grid.orbit-lab.org") do |node|
  node.addApplication("test:app:otg2") do |app|
    app.setProperty('udp:local_host', '192.168.0.2')
    app.setProperty('udp:dst_host', '192.168.0.3')
    app.setProperty('udp:dst_port', 3000)
    app.measure('udp_out', :samples => 1)
  end
  node.net.w0.mode = "adhoc"
  node.net.w0.type = 'g'
  node.net.w0.channel = channel
  node.net.w0.essid = essid
  node.net.w0.ip = "192.168.0.2"
end

defGroup('Receiver', "nodeX-Y.grid.orbit-lab.org") do |node|
  node.addApplication("test:app:otr2") do |app|
    app.setProperty('udp:local_host', '192.168.0.3')
    app.setProperty('udp:local_port', 3000)
    app.measure('udp_in', :samples => 1)
  end
  node.net.w0.mode = "adhoc"
  node.net.w0.type = 'g'
  node.net.w0.channel = channel
  node.net.w0.essid = essid
  node.net.w0.ip = "192.168.0.3"
end

onEvent(:ALL_UP_AND_INSTALLED) do |event|
  info "This is my second OMF experiment"
  wait 10
  allGroups.startApplications
  info "All my Applications are started now..."
  wait 60
  allGroups.stopApplications
  info "All my Applications are stopped now."
  Experiment.done
end


addTab(:defaults)
addTab(:graph2) do |tab|
  opts = { :postfix => %{This graph shows the Sequence Number from the UDP traffic.}, :updateEvery => 1 }
  tab.addGraph("Sequence_Number", opts) do |g|
    dataOut = Array.new
    dataIn = Array.new
    mpOut = ms('udp_out')
    mpIn = ms('udp_in')
    mpOut.project(:oml_ts_server, :seq_no).each do |sample|
      dataOut << sample.tuple
    end
    mpIn.project(:oml_ts_server, :seq_no).each do |sample|
      dataIn << sample.tuple
    end
    g.addLine(dataOut, :label => "Sender (outgoing UDP)")
    g.addLine(dataIn, :label => "Receiver (incoming UDP)")
  end
end

