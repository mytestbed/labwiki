

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
      
      info "SIGNED IN!!!!"
      OMF::Web::Rack::SessionAuthenticator.authenticate  
      OMF::Web::Rack::SessionAuthenticator[:name] = email
      info "Authenticated '#{email}' (#{Thread.current["sessionID"]})"
    end
  end
end