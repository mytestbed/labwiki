
require 'omf_common/lobject'

use ::Rack::ShowExceptions
#use ::Rack::Lint

OMF::Web::Runner.instance.life_cycle(:pre_rackup)
options = OMF::Web::Runner.instance.options

require 'omf-web/rack/session_authenticator'                               
use OMF::Web::Rack::SessionAuthenticator, #:expire_after => 10, 
          :login_page_url => '/resource/login/login.html',
          :no_session => ['^/resource/', '^/login', '^/logout']

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
      Labwiki::Authenticator.signon(req.params)
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



