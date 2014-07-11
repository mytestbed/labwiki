require 'warden/github'

module LabWiki::Authentication
  class Github < Authentication
    CONFIG = {
      :client_id     => ENV['GITHUB_CLIENT_ID']     || 'f46dfe94dd5a45f3a111',
      :client_secret => ENV['GITHUB_CLIENT_SECRET'] || '2886c19529fa83b41369755416a275953102584f',
      :scope         => 'user',
      :redirect_uri  => '/bob'
    }
  end
end
