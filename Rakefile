# Bundler is messing with that later on
GEM_PATH = ENV['_ORIGINAL_GEM_PATH']

# Setup bundler environment
TOP_DIR = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
ENV['BUNDLE_GEMFILE'] = File.join(TOP_DIR, 'Gemfile')
require 'bundler'
Bundler.setup()

require 'yaml'
require 'god'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/**/*_spec.rb"
  t.verbose = true
end



desc "Starting Labwiki as a daemon"
task :start, :config do |t, args|
  config = args[:config] || ENV['LW_CONFIG'] || "etc/labwiki/local.yaml"
  config = File.expand_path(config)
  abort "Config file '#{config}' NOT found" unless File.exist?(config)

  system("/usr/bin/env LW_CONFIG=#{config} bundle exec god -c etc/labwiki/labwiki.god")
  system('/usr/bin/env bundle exec god start labwiki')
end

desc "Stop the Labwiki Daemon"
task :stop do |t, args|
  system('/usr/bin/env bundle exec god stop labwiki')
end

desc "Print the status of the Labwiki daemon"
task :status do |t, args|
  system('/usr/bin/env bundle exec god status labwiki')
end

desc "Run  Labwiki in this shell"
task :run do |t, args|
  system("#{TOP_DIR}/bin/labwiki #{args.join(' ')} start")
end



desc "Call after 'bundle install --path vendor'"
task 'post-install' => [:create_server_bin]

task 'create_server_bin' do
  target = 'bin/labwiki'
  unless File.readable?("#{target}.in")
    abort "Can't find '#{target}.in' in local directory"
  end
  tmpl = File.read("#{target}.in")

  home = ENV['HOME']

  rvm_home = ruby = gemset = ''
  rvm_bin_path = ENV["rvm_bin_path"]

  if rvm_bin_path
    rvm_home = rvm_bin_path.match(/.*rvm/)[0]
    d, ruby, gemset = GEM_PATH.match(/.*(ruby.*)@(.*)/).to_a
  end

  s = tmpl.gsub('%HOME%', home).gsub('%RVM_HOME%', rvm_home).gsub('%RUBY%', ruby).gsub('%GEMSET%', gemset)
  File.open(target, 'w') do |f|
    f.write(s)
  end
  File.chmod(0755, target)
  puts ".. Created '#{target}'."
end

