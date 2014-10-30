require 'omf-web/session_store'
require 'labwiki/plugin_manager'
require 'labwiki/core_ext/object'

module LabWiki

  class SessionInit < OMF::Base::LObject
    def initialize(app, opts = {})
      @app = app
    end

    def call(env)
      req = ::Rack::Request.new(env)

      # Unless request resource files, most likely to be static
      unless req.path =~ /^\/resource/
        # Session ID should be in cookie, but if cookies don't work (iBook widgets) we try
        # to carry them in the parameters.
        #
        # see OMF::Web::SessionStore
        req.session['sid'] ||= req.params['sid'] || "s#{(rand * 10000000).to_i}_#{(rand * 10000000).to_i}"

        if req.params["project_id"] && OMF::Web::SessionStore[:current_project, :user] != req.params["project_id"]
          req.session['sid'] = req.params['sid'] || "s#{(rand * 10000000).to_i}_#{(rand * 10000000).to_i}"
        end

        Thread.current["sessionID"] = req.session['sid'] # needed for Session Store

        # Reset current project after new session created
        if req.params["project_id"]
          OMF::Web::SessionStore[:current_project, :user] = req.params["project_id"]
        end

        # Unless visiting public/unprotected pages
        unless req.path =~ /^\/(login|logout|unauthenticated|favicon.ico)/
          unless env['warden'].authenticated?
            if LabWiki::Authentication.none?
              # No login hack, set a default user
              env['warden'].set_user "https://localhost?id=xxx"
            else
              env['warden'].authenticate!(LabWiki::Authentication.type)
            end
          end
        end
      end

      @app.call(env)
    end

  end
end
