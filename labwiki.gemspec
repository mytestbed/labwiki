# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "labwiki/version"

Gem::Specification.new do |s|
  s.name        = "labwiki"
  s.version     = OmfLabWiki::VERSION.join('.')
#  s.version     = 0.1
  s.authors     = ["Max Ott"]
  s.email       = ["max.ott@nicta.com.au"]
  s.homepage    = "https://labwiki.mytestbed.net"
  s.summary     = %q{Web based experimentation environment.}
  s.description = %q{A web based environment to plan, prepare, execute, and analyse experiments in the OMF universe.}

  s.rubyforge_project = "labwiki"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "minitest", "~> 2.11.3"
  s.add_runtime_dependency "ruby_parser", "~> 2.3.1"
  #s.add_runtime_dependency "omf_web", "~> 0.9.0"
  s.add_runtime_dependency "warden-openid"
  s.add_runtime_dependency "i18n"
  s.add_development_dependency "pry"
end
