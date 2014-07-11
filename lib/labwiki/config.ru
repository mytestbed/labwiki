require 'omf_base/lobject'
#require 'omf-web/content/irods_repository'
require 'openid/store/filesystem'
require 'labwiki/authentication'
require 'labwiki/rack/session_init'

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
use ::Rack::CommonLogger

# AUTHENTICATION
LabWiki::Authentication.setup(LabWiki::Configurator["session/authentication"])

if LabWiki::Authentication.openid?
  use ::Rack::OpenID, OpenID::Store::Filesystem.new("/tmp/openid_#{LW_PORT}")
end

use Warden::Manager do |manager|
  manager.failure_app = LabWiki::Authentication::Failure
end
# END AUTHENTICATION

use LabWiki::SessionInit

OMF::Web::Runner.instance.life_cycle(:pre_rackup)
options = OMF::Web::Runner.instance.options

map "/labwiki" do
  handler = proc do |env|
    require 'labwiki/rack/top_handler'
    LabWiki::TopHandler.new(options).call(env)
  end
  run handler
end

# Immediately kick-off redirection to GENI's OpenID facility
map '/geni_login' do
  handler = proc do |env|
    puts "---- Geni Login: ENV: #{env.keys}"
    req = ::Rack::Request.new(env)
    req.update_param("openid_identifier", GENI_OPENID_PROVIDER)
    env['warden'].authenticate!(:openid)
    [302, {'Location' => '/', "Content-Type" => ""}, ['Login process failed']]
  end
  run handler
end

map '/logout' do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    env['warden'].logout(:default)
    LabWiki::PluginManager.close_session
    LabWiki::Configurator.close_session
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

map "/authorised" do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    if req.post?
      speak_for = req.params['data_credential']
      OMF::Web::SessionStore[:speak_for, :user] = speak_for
      #puts ">>>>>>>> CONFIG.RU - authorised: #{speak_for} -- #{req.params.keys} -- #{req.params}"

      require 'labwiki/plugin_manager'
      LabWiki::PluginManager.authorised()
      [302, {'Location' => '/labwiki', "Content-Type" => ""}, ['Next window!']]
    end
  end
  run handler
end

# Allow the plugins to add their own maps
LabWiki::PluginManager.extend_config_ru(binding)

OMF::Web::Runner.instance.life_cycle(:post_rackup)

