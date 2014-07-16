module LabWiki
  class Authentication
    class None < Authentication
      register_type :none

      def initialize(opts)
        super
        @identity_url = "https://localhost?id=xxx"
        if (@debug_user = LabWiki::Configurator['debug/user'])
          # keys have been symbolised, put them back into strings
          du = @debug_user
          @debug_user = {}
          du.each {|k, v| @debug_user[k.to_s] = v}
        else
          @debug_user = {
            'lw:auth_type' => 'NoLogin',
            'urn' => 'user1',
            'pretty_name' => "User 1"
          }
        end
      end

      def parse_user(user)
        user = @users[@identity_url] = @debug_user
        OMF::Web::SessionStore[:name, :user] = user['pretty_name']
        urn = user['urn']
        OMF::Web::SessionStore[:urn, :user] = urn
        OMF::Web::SessionStore[:id, :user] = urn && urn.split('|').last
      end
    end
  end
end
