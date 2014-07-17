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
            'id' => 'user1',
            'name' => "User 1"
          }
        end
      end

      def parse_user(identity_url)
        @identity_url = identity_url
        OMF::Web::SessionStore[:id, :user] = @debug_user['id']
        OMF::Web::SessionStore[:name, :user] = @debug_user['name']
        OMF::Web::SessionStore[:data, :user] = @debug_user
      end
    end
  end
end
