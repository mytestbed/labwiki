
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'labwiki', :searchPath => File.join(File.dirname(__FILE__), 'labwiki')

module OmfLabWiki; end

require 'omf-web/content/git_repository'
OMF::Web::GitContentRepository.register_git_repo(:foo, '/tmp/foo', true)

require 'labwiki/plugin_manager'

# Configure the web server
#
opts = {
  :app_name => 'labwiki',
  :page_title => 'LabWiki',
  :footer_left => lambda do
    #img :src => '/resource/image/imagined_by_nicta.jpeg', :height => 24
    text 'Imagined by NICTA'
  end,
  :footer_right => 'git:labwiki',
  
  :theme => 'labwiki/theme',
  :port => 4000,
  :rackup => File.dirname(__FILE__) + '/labwiki/config.ru',
  :handlers => {
    # Should be done in a better way
    :pre_rackup => lambda { 
      LabWiki::PluginManager.init 
    },
  }
}
require 'omf_web'
OMF::Web.start(opts)
