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
        end

        @debug_user['lw:auth_type'] ||= 'NoLogin'
        @debug_user['id'] ||= 'user1'
        @debug_user['name'] ||= "User 1"
        @debug_user['projects'] ||= [{ name: 'Default', uuid: SecureRandom.uuid }]
      end

      def parse_user(identity_url)
        @identity_url = identity_url
        [:id, :name, :projects].each do |k|
          OMF::Web::SessionStore[k, :user] = @debug_user[k.to_s]
        end
        OMF::Web::SessionStore[:data, :user] = @debug_user
      end
    end
  end
end
