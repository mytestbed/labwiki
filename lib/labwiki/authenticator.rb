require 'omf-web/session_store'

module Labwiki

  class AuthenticatorException < Exception; end
  class AuthenticationFailed < AuthenticatorException; end
  class AuthenticationRedirect < AuthenticatorException
    attr_reader :redirect_url

    def initialize(redirect_url)
      @redirect_url = redirect_url
    end
  end

  class Authenticator < OMF::Common::LObject
    def self.signon(req)
      params = req.params

      info "SIGNON - #{params.inspect}"

      params['openid_identifier'] || req.env['rack.openid.response'] ? _signon_openid(req.env) : _signon_password(params)

      #OMF::Web::Rack::SessionAuthenticator.authenticate
      name = req.env['warden'].user
      OMF::Web::Rack::SessionAuthenticator[:name] = name
      info "Authenticated '#{name}' (#{OMF::Web::SessionStore.session_id})"
      OMF::Web::SessionStore[:email, :user] = name
      OMF::Web::SessionStore[:name, :user] = name

      # Set the repos to search for content for each column
      OMF::Web::SessionStore[:plan, :repos] = nil
      OMF::Web::SessionStore[:prepare, :repos] = nil
      OMF::Web::SessionStore[:execute, :repos] = nil
    end

    def self._signon_password(params)
      email = params["email"]
      pw = params["password"]
      #remember = params["remember"] == "on"

      # This is the MOST useless authentication
      if email.empty? || pw.empty? || email != pw
        OMF::Web::Rack::SessionAuthenticator[:login_error] = "Unknown user or wrong password"
        raise OMF::Web::Rack::AuthenticationFailedException
      end
      true
    end

    @@openid_session = {}

    def self._signon_openid(env)
      env['warden'].authenticate!
    end
  end
end
