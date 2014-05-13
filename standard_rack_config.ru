require 'bundler/setup'

this_dir = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
top_dir = File.absolute_path(this_dir)
etc_dir = File.join(top_dir, 'etc', 'labwiki')
lib_dir = File.join(top_dir, 'lib')

$: << lib_dir

require 'omf_base/lobject'

OMF::Base::Loggable.init_log('labwiki', searchPath: etc_dir)

# Make the logger references less verbose
class Log4r::Logger
  def to_s
    "\#<#{@fullname}>"
  end

  def write(*args)
    info(*args)
  end
end

require 'omf_web'
require 'labwiki'
require 'labwiki/version'
require 'labwiki/plugin_manager'
require 'labwiki/configurator'

require 'omf-web/thin/runner'
OMF::Web::Runner.new(ARGV)

OMF::Web::Runner.instance.options[:no_login_required] = true
OMF::Web::Runner.instance.options[:app_name] = 'labwiki'
OMF::Web::Runner.instance.options[:page_title] = 'Labwiki'

OMF::Web::Theme.theme = 'labwiki/theme'
OMF::Base::Loggable.set_environment ENV['RACK_ENV']

LabWiki::Configurator.load_from("#{top_dir}/config/labwiki/#{ENV['RACK_ENV'] || 'development'}.yml")
LabWiki::Configurator.init

# Original config.ru
require 'omf_base/lobject'
require 'warden-openid'
require 'openid/store/filesystem'
require 'labwiki/ruby_openid_patch'
require 'omf-web/content/irods_repository'

LW_PORT = "#{LabWiki::Configurator[:port] || 4000}"

require 'rack/cors'
use Rack::Cors, debug: true do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :options]
  end
end

use ::Rack::ShowExceptions
use ::Rack::Session::Cookie, secret: LW_PORT, key: "labwiki.session.#{LW_PORT}"
use Rack::CommonLogger, OMF::Base::Loggable.logger('labwiki')

######## AUTHENTICATION SECTION - Should move into separate file

LOGIN_PAGE = '/resource/login/geni_openid.html'
#LOGIN_PAGE = '/resource/login/login.html'

OPENID_FIELDS = {
  google: ["http://axschema.org/contact/email", "http://axschema.org/namePerson/last"],
  geni: ['http://geni.net/projects', 'http://geni.net/slices',
         'http://geni.net/user/urn', 'http://geni.net/user/prettyname',
         'http://geni.net/irods/username', 'http://geni.net/irods/zone']
}

GENI_OPENID_PROVIDER = "https://portal.geni.net/server/server.php"
TRUST_REFERRER = "portal.geni.net"

use ::Rack::OpenID, OpenID::Store::Filesystem.new("/tmp/openid_#{LW_PORT}")

$users = {}

Warden::OpenID.configure do |config|
  config.required_fields = OPENID_FIELDS[:geni]
  config.user_finder do |response|
    identity_url = response.identity_url
    user_data = OpenID::AX::FetchResponse.from_success_response(response).data
    user_data['lw:auth_type'] = 'OpenID.GENI'
    puts ">>> IDENTITY_URL: #{identity_url}"
    $users[identity_url] = user_data
    identity_url
  end
end

module AuthFailureApp
  def self.call(env)
    [401, {'Location' => '/labwiki', "Content-Type" => ""}, [
      "<p>Authentication failed. #{env['warden'].message}<p>
         <a href='/labwiki/logout'>Try again</a>
      "
    ]]
  end
end

use Warden::Manager do |manager|
  manager.default_strategies :openid
  manager.failure_app = AuthFailureApp
end

######## END AUTHENTICATION SECTION


#OMF::Web::Runner.instance.life_cycle(:pre_rackup)
options = OMF::Web::Runner.instance.options

require 'labwiki/rack/session_init'
use LabWiki::SessionInit

map "/labwiki" do
  handler = proc do |env|
    require 'labwiki/rack/top_handler'
    LabWiki::TopHandler.new(options).call(env)
  end
  run handler
end

map '/login' do
  handler = proc do |env|
    req = ::Rack::Request.new(env)
    if req.post?
      env['warden'].authenticate!
      [302, {'Location' => '/', "Content-Type" => ""}, ['Login process failed']]
    else
      [302, {'Location' => LOGIN_PAGE, "Content-Type" => ""}, ['Redirect to login']]
    end
  end
  run handler
end

# Immediately kick-off redirection to GENI's OpenID facility
map '/geni_login' do
  handler = proc do |env|
    puts "---- Geni Login: ENV: #{env.keys}"
    req = ::Rack::Request.new(env)
    req.update_param("openid_identifier", GENI_OPENID_PROVIDER)
    env['warden'].authenticate!
    [302, {'Location' => '/', "Content-Type" => ""}, ['Login process failed']]
  end
  run handler
end

map '/logout' do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    env['warden'].logout(:default)
    LabWiki::PluginManager.stop_session
    LabWiki::Configurator.stop_session
    req.session['sid'] = nil
    req.session.clear
    [302, {'Location' => '/', "Content-Type" => ""}, ['Next window!']]
  end
  run handler
end

map "/resource/vendor/" do
  require 'omf-web/rack/multi_file'
  run OMF::Web::Rack::MultiFile.new(options[:static_dirs], :sub_path => 'vendor', :version => true)
end

map "/resource/plugin" do
  require 'labwiki/rack/plugin_resource_handler'
  run LabWiki::PluginResourceHandler.new()
end

map "/resource" do
  require 'omf-web/rack/multi_file'
  dirs = options[:static_dirs]
  dirs.insert(0, "#{top_dir}/htdocs")
  run OMF::Web::Rack::MultiFile.new(dirs)
end

map '/_ws' do
  begin
    require 'omf-web/rack/websocket_handler'
    run OMF::Web::Rack::WebsocketHandler.new # :backend => { :debug => true }
  rescue Exception => ex
    OMF::Base::Loggable.logger('web').error "#{ex}"
  end
end

map '/_update' do
  require 'omf-web/rack/update_handler'
  run OMF::Web::Rack::UpdateHandler.new
end

map '/_content' do
  require 'omf-web/rack/content_handler'
  run OMF::Web::Rack::ContentHandler.new
end

map '/_search' do
  require 'labwiki/rack/search_handler'
  run LabWiki::SearchHandler.new
end

map '/_column' do
  require 'labwiki/rack/column_handler'
  run LabWiki::ColumnHandler.new
end


map "/" do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    case req.path_info
    when '/'
      if req.referrer && req.referrer =~ /#{TRUST_REFERRER}/
        [302, {'Location' => '/geni_login', "Content-Type" => ""}, ['Next window!']]
      else
        [302, {'Location' => '/labwiki', "Content-Type" => ""}, ['Next window!']]
      end
    when '/favicon.ico'
      [302, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    when '/image/favicon.ico'
      [302, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    else
      OMF::Base::Loggable.logger('rack').warn "Can't handle request '#{req.path_info}'"
      [401, {"Content-Type" => ""}, "Sorry!"]
    end
  end
  run handler
end

# Allow the plugins to add their own maps
LabWiki::PluginManager.extend_config_ru(binding)

#OMF::Web::Runner.instance.life_cycle(:post_rackup)

