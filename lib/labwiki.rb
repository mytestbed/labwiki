
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'labwiki', :searchPath => File.join(File.dirname(__FILE__), 'labwiki')

module OmfLabWiki; end


require 'labwiki/plugin_manager'
require 'labwiki/configurator'

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
      LabWiki::Configurator.init_omf_web
    },
    :pre_parse => lambda do |p|
      p.separator ""
      p.separator "LabWiki options:"
      p.on("--lw-config CONFIG_FILE", "File to hold LabWiki's local configurations") do |fname|
        LabWiki::Configurator.load_from(fname)
      end
      p.separator ""
    end,
    # post_parse should return true if everything is ok
    :post_parse => lambda do
      unless LabWiki::Configurator.configured?
        OMF::Common::Loggable.logger(:opts).fatal "Missing --lw_config option"
        false
      else
        true
      end
    end
  }
}
require 'omf_web'
OMF::Web.start(opts)
