
require 'omf_common/lobject'

use ::Rack::ShowExceptions
#use ::Rack::Lint

OMF::Web::Runner.instance.life_cycle(:pre_rackup)
options = OMF::Web::Runner.instance.options

# This Rack element sets the SessionID which is used in many
# different places. The session ID is stored in a cookie.
#
# If there is no specific authenticator configured (for instance
# in debugging environments) It also initialises the session user
# to the account name this service is running under.
#
class SessionAuthenticatorHack
  def initialize(app, opts = {})
    @app = app
  end

  def call(env)
    req = ::Rack::Request.new(env)
    unless sid = req.cookies['sid']
      sid = "s#{(rand * 10000000).to_i}_#{(rand * 10000000).to_i}"
    end
    Thread.current["sessionID"] = sid  # needed for Session Store
    unless OMF::Web::SessionStore[:email, :user]
      require 'etc'
      user = Etc.getlogin
      OMF::Web::SessionStore[:email, :user] = user
      OMF::Web::SessionStore[:name, :user] = user
    end

    status, headers, body = @app.call(env)
    Rack::Utils.set_cookie_header!(headers, 'sid', sid) if sid
    [status, headers, body]
  end
end
use SessionAuthenticatorHack

unless options[:no_login_required]
  require 'omf-web/rack/session_authenticator'
  use OMF::Web::Rack::SessionAuthenticator, #:expire_after => 10,
            #:login_page_url => '/resource/login/login.html',
            :login_page_url => '/resource/login/openid.html',
            :no_session => ['^/resource/', '^/login', '^/logout']
end
require 'labwiki/authenticator'

map "/labwiki" do
  require 'labwiki/rack/top_handler'
  run LabWiki::TopHandler.new(options)
end

map '/login' do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    #puts req.POST.inspect
    if req.post?
      begin
        Labwiki::Authenticator.signon(req.params)
      rescue Labwiki::AuthenticationRedirect => rex
        next [307, {'Location' => rex.redirect_url, "Content-Type" => ""}, ['Authenticate!']]
      rescue Labwiki::AuthenticationFailed
        # fine
      end
    end
    [307, {'Location' => '/', "Content-Type" => ""}, ['Next window!']]
  end
  run handler
end

map '/logout' do
  handler = Proc.new do |env|
    OMF::Web::Rack::SessionAuthenticator.logout
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
    else
      OMF::Common::Loggable.logger('rack').warn "Can't handle request '#{req.path_info}'"
      [401, {"Content-Type" => ""}, "Sorry!"]
    end
  end
  run handler
end

OMF::Web::Runner.instance.life_cycle(:post_rackup)



