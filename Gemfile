source "https://rubygems.org"

gemspec
gem "omf_web", :git => 'git://github.com/mytestbed/omf_web', :tag => 'v0.9.10'
gem "httparty"
gem "pg"
gem "em-pg-client", "~> 0.2.1", :require => ['pg/em', 'em-synchrony/pg']
gem "em-pg-sequel"

# Install gems from each plugin
# Credit: http://madebynathan.com/2010/10/19/how-to-use-bundler-with-plugins-extensions
#

Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '*', "Gemfile")) do |gemfile|
  #puts "GEMFILE: #{gemfile}"
  eval(IO.read(gemfile), binding)
end