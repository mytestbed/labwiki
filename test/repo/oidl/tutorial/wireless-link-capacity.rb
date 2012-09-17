#
# Copyright (c) 2006-2010 National ICT Australia (NICTA), Australia
#
# Tutorial experiment
#
defProperty('res1', 'omf.nicta.node11', "ID of sender node")
defProperty('res2', 'omf.nicta.node12', "ID of receiver node")
defProperty('packetsize', 512, "Packet size (byte) from the sender node")
defProperty('bitrate', 2000000, "Bitrate (bit/s) from the sender node")
defProperty('steps', 7, "Double bandwidth at each step")
defProperty('wifiType', "g", "The type of WIFI to use in this experiment")
defProperty('channel', '6', "The WIFI channel to use in this experiment")
defProperty('netid', "example2", "The ESSID to use in this experiment")

defGroup('Sender',property.res1) do |node|
  node.addApplication("test:app:otg2") do |app|
    app.setProperty('udp:local_host', '192.168.0.2')
    app.setProperty('udp:dst_host', '192.168.0.3')
    app.setProperty('udp:dst_port', 3000)
    app.setProperty('cbr:size', property.packetsize)
    app.setProperty('cbr:rate', property.bitrate)
    app.measure('udp_out', :interval => 1) do |mp|
      mp.filter('ts', 'first')
      mp.filter('pkt_length', 'sum')
    end
  end
  node.net.w0.mode = "adhoc"
  node.net.w0.type = property.wifiType
  node.net.w0.channel = property.channel
  node.net.w0.essid = property.netid
  node.net.w0.ip = "192.168.0.2"
end

defGroup('Receiver',property.res2) do |node|
  node.addApplication("test:app:otr2") do |app|
    app.setProperty('udp:local_host', '192.168.0.3')
    app.setProperty('udp:local_port', 3000)
    app.measure('udp_in', :interval => 1) do |mp|
      mp.filter('ts', 'first')
      mp.filter('pkt_length', 'sum')
    end
  end
  node.net.w0.mode = "adhoc"
  node.net.w0.type = property.wifiType
  node.net.w0.channel = property.channel
  node.net.w0.essid = property.netid
  node.net.w0.ip = "192.168.0.3"
end

onEvent(:ALL_UP_AND_INSTALLED) do |event|
  wait 5
  allGroups.startApplications
  info "All my Applications are started now..."
  br = property.bitrate.value
  property.steps.value.times do |i|
    wait 5
    property.bitrate =  (i + 1) * br
  end

  allGroups.stopApplications
  info "All my Applications are stopped now."
  Experiment.done
end

defGraph 'Throughput' do |g|
  g.ms('udp_in').select {[ oml_ts_client.as(:ts), pkt_length_sum.as(:rate) ]}
  g.caption "Incoming traffic on receiver."
  g.type 'line_chart3'
  g.mapping :x_axis => :ts, :y_axis => :rate
  g.xaxis :legend => 'time [s]'
  g.yaxis :legend => 'size [B]', :ticks => {:format => 's'}
end

