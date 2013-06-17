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


    def self.signon(params)
      debug "SIGNON - #{params.inspect}"

      params['openid_url'] ? _signon_openid(params) : _signon_password(params)

      OMF::Web::Rack::SessionAuthenticator.authenticate
      OMF::Web::Rack::SessionAuthenticator[:name] = email
      info "Authenticated '#{email}' (#{OMF::Web::SessionStore.session_id})"
      OMF::Web::SessionStore[:email, :user] = email
      OMF::Web::SessionStore[:name, :user] = email

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

    def self._signon_openid(params)
      require 'openid'

      openid_url = params['openid_url']
      c = OpenID::Consumer.new(@@openid_session, nil)
      e = c.begin(openid_url)
      url = e.redirect_url 'labwiki.mytestbed.net', 'http://labwiki.mytestbed.net'
      raise AuthenticationRedirect.new(url)
    end
  end
end
