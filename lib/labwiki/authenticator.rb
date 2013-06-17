require 'omf-web/session_store'


module Labwiki
  class Authenticator < OMF::Common::LObject


    def self.signon(params)
      debug "SIGNON - #{params.inspect}"

      email = params["email"]
      pw = params["password"]
      #remember = params["remember"] == "on"

      # This is the MOST useless authentication
      if email.empty? || pw.empty? || email != pw
        OMF::Web::Rack::SessionAuthenticator[:login_error] = "Unknown user or wrong password"
        return
      end

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
  end
end
