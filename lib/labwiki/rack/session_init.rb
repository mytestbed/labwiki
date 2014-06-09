# require 'grit'
# require 'httparty'
# require 'omf-web/content/git_repository'
require 'omf-web/session_store'
require 'labwiki/plugin_manager'

module LabWiki

  class SessionInit < OMF::Base::LObject
    def initialize(app, opts = {})
      @app = app
    end

    def call(env)
      req = ::Rack::Request.new(env)
      unless req.path =~ /^\/resource/ || req.path == '/login' # Do not care about resource files

        # Session ID should be in cookie, but if cookies don't work (iBook widgets) we try
        # to carry them in the parameters.
        #
        # see OMF::Web::SessionStore
        #
        req.session['sid'] ||= req.params['sid'] || "s#{(rand * 10000000).to_i}_#{(rand * 10000000).to_i}"
        Thread.current["sessionID"] = req.session['sid'] # needed for Session Store

        # No login hack, set a default user called user1
        if OMF::Web::Runner.instance.options[:no_login_required] && !env['warden'].authenticated?
          if debug_user = LabWiki::Configurator['debug/user']
            # keys have been symbolised, put them back into strings
            du = debug_user
            debug_user = {}
            du.each {|k, v| debug_user[k.to_s] = v}
          else
            debug_user = {
              'lw:auth_type' => 'NoLogin',
              'urn' => 'user1',
              'pretty_name' => "User 1"
            }
          end
          OMF::Web::SessionStore[:name, :user] = debug_user['pretty_name']
          urn = debug_user['urn']
          OMF::Web::SessionStore[:urn, :user] = urn
          OMF::Web::SessionStore[:id, :user] = urn && urn.split('|').last

          identity_url = "https://localhost?id=xxx"
          debug "Debug user: #{debug_user}"
          $users[identity_url] = debug_user
          env['warden'].set_user identity_url
        end

        user = nil
        if env['warden'].authenticated?
          user = $users[env['warden'].user]
        end
        if user.nil?
          req.session['sid'] = nil # necessary?
          req.session.clear
          if req.xhr?
            return [401, {}, ['Session lost, re-authenticate.']]
          else
            if OMF::Web::Runner.instance.options[:no_login_required]
              return [302, {'Location' => req.path, "Content-Type" => ""}, ['Session lost - Retry.']]
            end
            return [302, {'Location' => '/login', "Content-Type" => ""}, ['Session lost, re-authenticate.']]
          end
        end

        unless OMF::Web::SessionStore[:initialised, :session]
          LabWiki::Configurator.start_session(user)
          LabWiki::PluginManager.init_session()
          LabWiki::LWWidget.init_session()
          OMF::Web::SessionStore[:initialised, :session] = true
        end
        #end
      end
      @app.call(env)
    end
  end
end
