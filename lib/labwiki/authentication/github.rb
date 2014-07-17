require 'warden/github'

module LabWiki
  class Authentication
    class Github < Authentication
      register_type :github

      CONFIG = {
        :client_id     => ENV['GITHUB_CLIENT_ID']     || 'f46dfe94dd5a45f3a111',
        :client_secret => ENV['GITHUB_CLIENT_SECRET'] || '2886c19529fa83b41369755416a275953102584f',
        :scope         => 'user',
      }

      def initialize(opts)
        super
      end

      def configure_warden(manager)
        super
        manager.scope_defaults :default, config: CONFIG
      end

      def parse_user(user)
        OMF::Web::SessionStore[:id, :user] = user.id
        OMF::Web::SessionStore[:name, :user] = user.name || "Unknown"
      end
    end
  end
end
