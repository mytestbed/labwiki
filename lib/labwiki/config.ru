require 'omf_common/lobject'
require 'warden-openid'

use ::Rack::ShowExceptions
use ::Rack::Session::Cookie, secret: "715aba35a6980113aa418ec18af31411", key: 'labwiki.session'
use ::Rack::OpenID

$users = {}

Warden::OpenID.configure do |config|
  config.user_finder do |response|
    $users[response.identity_url]
  end
end

module AuthFailureApp
  def self.call(env)
    req = ::Rack::Request.new(env)
    if openid = env['warden.options'][:openid]
      # OpenID authenticate success, but user is missing (Warden::OpenID.user_finder returns nil)
      identity_url = openid[:response].identity_url
      $users[identity_url] = identity_url
      env['warden'].set_user identity_url
      [307, {'Location' => '/labwiki', "Content-Type" => ""}, ['Next window!']]
    else
      # When OpenID authenticate failure
      [401, {'Location' => '/labwiki', "Content-Type" => ""}, ['Next window!']]
    end
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

map "/dump" do
  handler = proc do |env|
    req = ::Rack::Request.new(env)
    omf_exp_id = req.params['domain']
    dump_cmd = File.expand_path(LabWiki::Configurator[:gimi][:dump_script])

    exp = nil
    OMF::Web::SessionStore.find_across_sessions do |content|
      content["omf:exps"] && (exp = content["omf:exps"].find { |v| v[:id] == omf_exp_id } )
    end

    if exp
      i_token = exp[:irods_token]
      i_path = exp[:irods_path]

      dump_cmd << " --domain #{omf_exp_id} --token #{i_token} --path #{i_path}"
      EM.popen(dump_cmd)
      [200, {}, "Dump script triggered. <br /> Using command: #{dump_cmd} <br /> Unfortunately we cannot show you the progress."]
    else
      [500, {}, "Cannot find experiment(task) by domain id #{omf_exp_id}"]
    end
  end
  run handler
end

map "/labwiki" do
  handler = proc do |env|
    if options[:no_login_required]
      identity_url = "https://localhost?id=user1"
      $users[identity_url] = identity_url
      env['warden'].set_user identity_url

      require 'labwiki/rack/top_handler'
      LabWiki::TopHandler.new(options).call(env)
    elsif env['warden'].authenticated?
      require 'labwiki/rack/top_handler'
      LabWiki::TopHandler.new(options).call(env)
    else
      [307, {'Location' => '/resource/login/openid.html', "Content-Type" => ""}, ['Authenticate!']]
    end
  end
  run handler
end

map '/login' do
  handler = proc do |env|
    req = ::Rack::Request.new(env)
    if req.post?
      env['warden'].authenticate!
      [307, {'Location' => '/', "Content-Type" => ""}, ['Next window!']]
    end
  end
  run handler
end

map '/logout' do
  handler = Proc.new do |env|
    env['warden'].logout(:default)
    [307, {'Location' => '/', "Content-Type" => ""}, ['Next window!']]
  end
  run handler
end

map "/resource/vendor/" do
  require 'omf-web/rack/multi_file'
  run OMF::Web::Rack::MultiFile.new(options[:static_dirs], :sub_path => 'vendor', :version => true)
end

map "/resource" do
  require 'omf-web/rack/multi_file'
  dirs = options[:static_dirs]
  dirs.insert(0, "#{File.dirname(__FILE__)}/../../htdocs")
  run OMF::Web::Rack::MultiFile.new(dirs)
end

map "/plugin" do
  require 'labwiki/rack/plugin_resource_handler'
  run LabWiki::PluginResourceHandler.new()
end


map '/_ws' do
  begin
    require 'omf-web/rack/websocket_handler'
    run OMF::Web::Rack::WebsocketHandler.new # :backend => { :debug => true }
  rescue Exception => ex
    OMF::Common::Loggable.logger('web').error "#{ex}"
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
      [307, {'Location' => '/labwiki', "Content-Type" => ""}, ['Next window!']]
    when '/favicon.ico'
      [301, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    when '/image/favicon.ico'
      [301, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    else
      OMF::Common::Loggable.logger('rack').warn "Can't handle request '#{req.path_info}'"
      [401, {"Content-Type" => ""}, "Sorry!"]
    end
  end
  run handler
end

OMF::Web::Runner.instance.life_cycle(:post_rackup)

