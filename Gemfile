source "https://rubygems.org"

def override_with_local(opts)
  local_dir = opts.delete(:path)
  unless local_dir.start_with? '/'
    local_dir = File.join(File.dirname(__FILE__), local_dir)
  end
  #puts "Checking for '#{local_dir}' - #{Dir.exist?(local_dir)}"
  Dir.exist?(local_dir) ? {path: local_dir} : opts
end

gem "rake"
gem "omf_oml", override_with_local(path: '../omf_oml', github: 'mytestbed/omf_oml')
gem "omf_web", override_with_local(path: '../omf_web', github: 'mytestbed/omf_web')
gem "httparty"
gem "god"
gem 'rack-cors', :require => 'rack/cors'
gem "i18n"
gem "rack-fiber_pool"

# Install gems from each plugin
# Credit: http://madebynathan.com/2010/10/19/how-to-use-bundler-with-plugins-extensions
#
Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '*', "Gemfile")) do |gemfile|
  #puts "GEMFILE: #{gemfile}"
  eval(IO.read(gemfile), binding)
end

group :warden do
  gem "warden-openid"
  gem "warden-github"
end

group :dev do
  gem "pry"
end

# Only needed for gitolite integration. To exclude it using --without gitolite when running bundler
group :gitolite do
  gem "rugged"
end
