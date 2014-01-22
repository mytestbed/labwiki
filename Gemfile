source "https://rubygems.org"

def override_with_local(opts)
  local_dir = opts.delete(:path)
  unless local_dir.start_with? '/'
    local_dir = File.join(File.dirname(__FILE__), local_dir)
  end
  puts "Checking for '#{local_dir}' - #{Dir.exist?(local_dir)}"
  Dir.exist?(local_dir) ? {path: local_dir} : opts
end

gemspec
#gem "omf_web", override_with_local(path: '../omf_web', git: 'git://github.com/mytestbed/omf_web', tag: 'v0.9.10')
gem "omf_web", override_with_local(path: '../omf_web', git: 'git://github.com/mytestbed/omf_web')
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