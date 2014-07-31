
DIR = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
BIN_DIR = File.absolute_path(File.join(DIR, '..', '..', 'bin'))

God.watch do |w|
  w.name = "labwiki"
  w.start = "#{BIN_DIR}/labwiki --lw-config #{File.join(DIR, 'labwiki.yaml')} start"
  w.log = '/tmp/labwiki.log'
  w.keepalive
end
