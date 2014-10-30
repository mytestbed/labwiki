require 'net/https'

module Warden
  module Persona
    # A Warden Strategy to authenticate with Persona from Mozilla
    #
    class Strategy < Warden::Strategies::Base

      VERIFY_URL = "verifier.login.persona.org"

      def valid?
        # Not valid when the assertion parameter is missing
        return false unless params["assertion"]

        # Prepare the HTTP request to verify
        http = Net::HTTP.new(VERIFY_URL, 443)
        http.use_ssl = true
        req = Net::HTTP::Post.new("/verify")
        req.set_form_data( { assertion: params["assertion"], audience: request.host_with_port } )

        # POST args to verifier and get response
        response = http.request(req)

        json = JSON.parse response.body
        @asserted = json


        # Return true if asserted email and audience is right
        json["status"] == "okay" and json["audience"] == request.host_with_port
      end

      # We welcome everyone with an email
      def authenticate!
        u = @asserted["email"]
        u.nil? ? fail!("No email given.") : success!(u)
      end
    end
  end
end

Warden::Strategies.add(:persona, Warden::Persona::Strategy)
