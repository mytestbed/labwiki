
require 'bundler/setup'

this_dir = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
top_dir = File.absolute_path(File.join(this_dir, '..', '..'))
etc_dir = File.join(top_dir, 'etc', 'labwiki')
lib_dir = File.join(top_dir, 'lib')

$: << lib_dir

require 'omf_base/lobject'
OMF::Base::Loggable.init_log 'labwiki', :searchPath => etc_dir

# Make the logger references less verbose
class Log4r::Logger
  def to_s
    "\#<#{@fullname}>"
  end
end

require 'omf_web'
require 'labwiki'
require 'labwiki/version'
require 'labwiki/plugin_manager'
require 'labwiki/configurator'

config_file = ENV['LW_CONFIG'] || File.join(etc_dir, 'labwiki.yaml')

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
  :rackup => File.join(lib_dir, 'labwiki', 'config.ru'),
  #:login_required => true,
  :handlers => {
    # Should be done in a better way
    # :pre_rackup => lambda do
      # LabWiki::Configurator.init_omf_web
    # end,
    :pre_parse => lambda do |p|
      p.separator ""
      p.separator "LabWiki options:"
      p.on("--lw-config CONFIG_FILE", "File to hold LabWiki's local configurations") do |fname|
        config_file = fname
        #LabWiki::Configurator.load_from(fname)
      end
      p.on("--lw-no-login", "If set, all sessions are automatically assigned to local account") do
        OMF::Web::Runner.instance.options[:no_login_required] = true
      end
      p.on("--use-rack-common-logger", "If set, display each HTTP request") do
        OMF::Web::Runner.instance.options[:use_rack_common_logger] = true
      end
      p.separator ""
    end,
    # post_parse should return true if everything is ok
    :post_parse => lambda do |r|
      OMF::Base::Loggable.logger(:start).info "Starting LabWiki V#{LabWiki.version}"

      unless config_file.start_with? '/'
        config_file = File.join(ENV['LW_REF_DIR'] || ENV['PWD'], config_file)
      end
      unless File.readable? config_file
        OMF::Base::Loggable.logger(:opts).fatal "Missing config file '#{config_file}'"
        exit(-1)

      end
      LabWiki::Configurator.load_from(config_file)
      unless LabWiki::Configurator.configured?
        OMF::Base::Loggable.logger(:opts).fatal "Missing --lw_config option"
        false
      else
        LabWiki::Configurator.init
        #LabWiki::PluginManager.init
        true
      end
    end,

  }
}


OMF::Web.start(opts)

