
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'labwiki'

module OmfLabWiki; end

# Configure the web server
#
opts = {
  :page_title => 'LabWiki',
  :theme => 'labwiki/theme',
  :port => 4000,
  :rackup => File.dirname(__FILE__) + '/labwiki/config.ru',
}
require 'omf_web'
OMF::Web.start(opts)
