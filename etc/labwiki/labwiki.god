#!/usr/bin/env ruby

DIR = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
BIN_DIR = File.absolute_path(File.join(DIR, '..', '..', 'bin'))

lw_config = ENV["LW_CONFIG"]

God.watch do |w|
  w.name = "labwiki"
  w.start = "#{BIN_DIR}/labwiki --lw-config #{lw_config} start"
  w.log = '/var/tmp/labwiki.log'
  w.keepalive
end
