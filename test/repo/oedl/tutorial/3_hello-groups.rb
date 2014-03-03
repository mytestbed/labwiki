essid = (0...8).map{65.+(rand(25)).chr}.join
channel = rand(11)+1

defGroup('Sender', "nodeX-Y.grid.orbit-lab.org") do |node|
  node.addApplication("test:app:otg2") do |app|
    app.setProperty('udp:local_host', '%net.w0.ip%')
    app.setProperty('udp:dst_host', '192.168.255.255')
    app.setProperty('udp:broadcast', 1)
    app.setProperty('udp:dst_port', 3000)
    app.measure('udp_out', :samples => 1)
  end
end

defGroup('Receiver', "nodeX-Y.grid.orbit-lab.org") do |node|
  node.addApplication("test:app:otr2") do |app|
    app.setProperty('udp:local_host', '192.168.255.255')
    app.setProperty('udp:local_port', 3000)
    app.measure('udp_in', :samples => 1)
  end
end

allGroups.net.w0 do |interface|
  interface.mode = "adhoc"
  interface.type = 'g'
  interface.channel = channel
  interface.essid = essid
  interface.ip = "192.168.0.%index%"
end

onEvent(:ALL_UP_AND_INSTALLED) do |event|
  wait 10
  group("Receiver").startApplications
  wait 5
  group("Sender").startApplications
  wait 30
  group("Sender").stopApplications
  wait 5
  group("Receiver").stopApplications
  Experiment.done
end
