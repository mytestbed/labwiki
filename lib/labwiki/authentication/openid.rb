require 'warden-openid'
require 'labwiki/ruby_openid_patch'

module LabWiki
  class Authentication
    class OpenID < Authentication
      register_type :openid

      PROVIDERS = {
        "google" => {
          provider: "http://www.google.com/accounts/o8/id",
          required_fields: [
            "http://axschema.org/namePerson/last",
            "http://axschema.org/contact/email",
            "http://axschema.org/namePerson/first"
          ]
        },
        "geni" => {
          provider: "https://portal.geni.net/server/server.php",
          required_fields: [
            "http://geni.net/projects",
            "http://geni.net/slices",
            "http://geni.net/user/urn",
            "http://geni.net/user/prettyname",
            "http://geni.net/irods/username",
            "http://geni.net/irods/zone"
          ]
        }
      }

      def initialize(opts)
        super(opts)
        # Default we let google do it
        @provider = opts[:provider] || "google"

        Warden::OpenID.configure do |config|
          config.required_fields = PROVIDERS[@provider][:required_fields]
          config.user_finder do |response|
            identity_url = response.identity_url
            user_data = ::OpenID::AX::FetchResponse.from_success_response(response).data
            user_data['lw:auth_type'] = "openid.#{@provider}"
            @users[identity_url] = user_data
            identity_url
          end
        end
      end

      def parse_user(user)
        user = @users[user]
        case @provider
        when "geni"
          pretty_name = user['http://geni.net/user/prettyname'].try(:first)

          if (urn = user['http://geni.net/user/urn'].try(:first))
            OMF::Web::SessionStore[:urn, :user] = urn.gsub '|', '+'
            OMF::Web::SessionStore[:id, :user] = urn && urn.split('|').last
          end
          if (irods_user = user['http://geni.net/irods/username'].try(:first))
            OMF::Web::SessionStore[:id, :irods_user] = irods_user
          end
          if (irods_zone = user['http://geni.net/irods/zone'].try(:first))
            OMF::Web::SessionStore[:id, :irods_zone] = irods_zone
          end
        when "google"
          last_name = user["http://axschema.org/namePerson/last"].try(:first)
          first_name = user["http://axschema.org/namePerson/first"].try(:first)
          pretty_name = "#{first_name} #{last_name}"
          OMF::Web::SessionStore[:id, :user] = user["http://axschema.org/contact/email"].try(:first)
        end

        OMF::Web::SessionStore[:name, :user] = pretty_name || "Unknown"
      end
    end
  end
end
