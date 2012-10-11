defProperty('source', "omf.nodeX", "ID of a resource")
defProperty('sink', "omf.nodeY", "ID of a resource")

defApplication('ping_app', 'pingmonitor') do |a|
  a.path = "/root/pingWrap.rb" 
  a.version(1, 2, 0)
  a.shortDescription = "Wrapper around ping" 
  a.description = "ping application" 
  a.defProperty('dest_addr', 'Address to ping', 'a', {:type => :string, :dynamic => false})
  a.defProperty('count', 'Number of times to ping', 'c', {:type => :integer, :dynamic => false}) 
  a.defProperty('interval', 'Interval between pings in s', 'i', {:type => :integer, :dynamic => false})

  a.defMeasurement('myping') do |m|
    m.defMetric('dest_addr',:string) 
    m.defMetric('ttl',:int)
    m.defMetric('rtt',:float)
    m.defMetric('rtt_unit',:string)
 end
end

defGroup('Source', property.source) do |node|
  node.addApplication("ping_app") do |app|
    app.setProperty('dest_addr', property.sink)
    app.setProperty('count', 10)
    app.setProperty('interval', 1)
    app.measure('myping', :samples => 1)
  end
end

onEvent(:ALL_UP_AND_INSTALLED) do |event|
  info "Starting the ping" 
  group('Source').startApplications
  wait 11
  info "Stopping the ping" 
  group('Source').stopApplications
  Experiment.done
end
