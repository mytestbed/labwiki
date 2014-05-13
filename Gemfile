source "https://rubygems.org"

def override_with_local(opts)
  local_dir = opts.delete(:path)
  unless local_dir.start_with? '/'
    local_dir = File.join(File.dirname(__FILE__), local_dir)
  end
  Dir.exist?(local_dir) ? {path: local_dir} : opts
end

gemspec
gem "omf_web", override_with_local(path: '../omf_web', github: "mytestbed/omf_web")
gem "omf_base", override_with_local(path: '../omf_base', github: "mytestbed/omf_base", tag: "v1.0.3")
gem "httparty"
gem "god"
gem 'rack-cors', :require => 'rack/cors'

# Install gems from each plugin
# Credit: http://madebynathan.com/2010/10/19/how-to-use-bundler-with-plugins-extensions
#
Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '*', "Gemfile")) do |gemfile|
  eval(IO.read(gemfile), binding)
end

group :test do
  gem 'minitest'
  gem 'capybara'
  gem 'capybara_minitest_spec'
  gem 'capybara-webkit'
  gem 'simplecov'
end
