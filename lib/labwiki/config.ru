require 'omf_base/lobject'
require 'warden-openid'
require 'omf-web/content/irods_repository'


use ::Rack::ShowExceptions
use ::Rack::Session::Cookie, secret: "715aba35a6980113aa418ec18af31411", key: 'labwiki.session'
use ::Rack::OpenID

$users = {}

OPENID_FIELDS = {
  google: ["http://axschema.org/contact/email", "http://axschema.org/namePerson/last"],
  geni: ['http://geni.net/projects', 'http://geni.net/slices', 'http://geni.net/user/urn', 'http://geni.net/user/prettyname']
}

Warden::OpenID.configure do |config|
  config.required_fields = OPENID_FIELDS[:geni]
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
      user_data = OpenID::AX::FetchResponse.from_success_response(openid[:response]).data
      $users[identity_url] = user_data
      env['warden'].set_user identity_url

      [307, {'Location' => '/labwiki', "Content-Type" => ""}, ['Authenticated.']]
    else
      # When OpenID authenticate failure
      [401, {'Location' => '/labwiki', "Content-Type" => ""}, ['Authentication failed.']]
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

# These should go to a separate controller/handler file.
map "/create_script" do
  handler = lambda do |env|
    req = ::Rack::Request.new(env)
    file_ext = req.params['file_ext'].downcase
    file_name = "#{req.params['file_name']}.#{file_ext}"
    sub_folder = case file_ext
                 when 'rb'
                   'oidl'
                 when 'md'
                   'wiki'
                 end
    repo = (LabWiki::Configurator[:repositories] || {}).first
    if repo.class == Array
      repo = OMF::Web::ContentRepository.find_repo_for("#{repo[1][:type]}:#{repo[0]}")
    end
    repo ||= (OMF::Web::SessionStore[:prepare, :repos] || []).first

    begin
      if repo.class == OMF::Web::IRodsContentRepository
        # iRods needs full path...
        path = "#{LabWiki::Configurator[:gimi][:irods][:home]}/#{sub_folder}/#{file_name}"
      else
        path = "repo/#{sub_folder}/#{file_name}"
      end

      repo.write(path, "", "Adding new script #{file_name}")
    rescue => e
      if e.class == RuntimeError && e.message =~ /Cannot write to file/
        repo.write("#{sub_folder}/#{file_name}", "", "Adding new script #{file_name}")
      else
        puts ">>> Write new files error: #{e.message}"
      end
    end
    [200, {}, "#{file_name} created"]
  end
  run handler
end

map "/dump" do
  handler = lambda do |env|
    req = ::Rack::Request.new(env)
    omf_exp_id = req.params['domain']
    if LabWiki::Configurator[:gimi] && LabWiki::Configurator[:gimi][:dump_script]
      dump_cmd = File.expand_path(LabWiki::Configurator[:gimi][:dump_script])
    else
      return [500, {}, "Dump script not configured."]
    end

    exp = nil
    OMF::Web::SessionStore.find_across_sessions do |content|
      content["omf:exps"] && (exp = content["omf:exps"].find { |v| v[:id] == omf_exp_id } )
    end

    if exp
      i_path = "#{exp[:irods_path]}/#{LabWiki::Configurator[:gimi][:irods][:measurement_folder]}" rescue "#{exp[:irods_path]}"

      dump_cmd << " --domain #{omf_exp_id} --path #{i_path}"
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
      u_data = 'user1'
      $users[identity_url] = u_data
      env['warden'].set_user u_data

      require 'labwiki/rack/top_handler'
      LabWiki::TopHandler.new(options).call(env)
    elsif env['warden'].authenticated?
      require 'labwiki/rack/top_handler'
      LabWiki::TopHandler.new(options).call(env)
    else
      [307, {'Location' => '/resource/login/openid.html', "Content-Type" => ""}, ['Authenticated!']]
    end
  end
  run handler
end

map '/login' do
  handler = proc do |env|
    req = ::Rack::Request.new(env)
    if req.post?
      env['warden'].authenticate!
      [307, {'Location' => '/', "Content-Type" => ""}, ['Login process failed']]
    end
  end
  run handler
end

map '/logout' do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    env['warden'].logout(:default)
    req.session['sid'] = nil
    req.session.clear
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
      [307, {'Location' => '/labwiki', "Content-Type" => ""}, ['Next window!']]
    when '/favicon.ico'
      [307, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    when '/image/favicon.ico'
      [307, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    else
      OMF::Base::Loggable.logger('rack').warn "Can't handle request '#{req.path_info}'"
      [401, {"Content-Type" => ""}, "Sorry!"]
    end
  end
  run handler
end

OMF::Web::Runner.instance.life_cycle(:post_rackup)

