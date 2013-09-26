#
# This is a test program listening for OVS port assignment information
#
require 'omf_oml/endpoint'
require 'omf_oml/table'

APPNAME = File.basename($0).split('.')[0]

require 'omf_base/lobject'
OMF::Base::Loggable.init_log APPNAME

PORT=3000

ep = OMF::OML::OmlEndpoint.new(PORT)
#toml = OMF::OML::OmlTable.new('oml', [[:x], [:y]], :max_size => 20)
ep.on_new_stream() do |name, stream|
  puts "New stream: #{name}::#{stream}"
  stream.on_new_tuple() do |t|
    puts "New tuple: #{t.to_a.inspect}"
#    toml.add_row(v.select(:oml_ts, :value))
  end
end


include OMF::Base::Loggable
info "Listening on port '#{PORT}'"
ep.run(false)
