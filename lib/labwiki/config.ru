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
use ::Rack::OpenID, OpenID::Store::Filesystem.new("/tmp/openid_#{LW_PORT}")

$users = {}

OPENID_FIELDS = {
  google: ["http://axschema.org/contact/email", "http://axschema.org/namePerson/last"],
  geni: ['http://geni.net/projects', 'http://geni.net/slices',
         'http://geni.net/user/urn', 'http://geni.net/user/prettyname',
         'http://geni.net/irods/username', 'http://geni.net/irods/zone']
}

GENI_OPENID_PROVIDER = "https://portal.geni.net/server/server.php"
TRUST_REFERRER = "portal.geni.net"

Warden::OpenID.configure do |config|
  config.required_fields = OPENID_FIELDS[:geni]
  config.user_finder do |response|
    identity_url = response.identity_url
    user_data = OpenID::AX::FetchResponse.from_success_response(response).data
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

OMF::Web::Runner.instance.life_cycle(:pre_rackup)
options = OMF::Web::Runner.instance.options

require 'labwiki/session_init'
use SessionInit

map "/labwiki" do
  handler = proc do |env|
    if env['warden'].authenticated?
      require 'labwiki/rack/top_handler'
      LabWiki::TopHandler.new(options).call(env)
    else
      [302, {'Location' => '/resource/login/openid.html', "Content-Type" => ""}, ['Redirect to login']]
    end
  end
  run handler
end

map '/login' do
  handler = proc do |env|
    req = ::Rack::Request.new(env)
    if req.post?
      env['warden'].authenticate!
      [302, {'Location' => '/', "Content-Type" => ""}, ['Login process failed']]
    end
  end
  run handler
end

# Immediately kick-off redirection to GENI's OpenID facility
map '/geni_login' do
  handler = proc do |env|
    puts "ENV: #{env.keys}"
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
    LabWiki::Plugin::Experiment::Util.disconnect_all_db_connections
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
  dirs.insert(0, "#{File.dirname(__FILE__)}/../../htdocs")
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

OMF::Web::Runner.instance.life_cycle(:post_rackup)

