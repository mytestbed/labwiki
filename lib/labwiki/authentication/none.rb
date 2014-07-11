module LabWiki
  class Authentication
    class None < Authentication
      register_type :none

      def initialize(opts)
        @identity_url = "https://localhost?id=xxx"
        super
      end

      def parse_user(user)
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

        debug "Debug user: #{debug_user}"
        @users[@identity_url] = debug_user
      end
    end
  end
end
