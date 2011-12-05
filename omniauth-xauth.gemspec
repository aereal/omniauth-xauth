# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-xauth/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-xauth"
  s.version     = OmniAuth::XAuth::VERSION
  s.authors     = ["aereal"]
  s.email       = ["aereal@kerare.org"]
  s.homepage    = "https://github.com/aereal/omniauth-xauth"
  s.summary     = %q{Abstract XAuth strategy for OmniAuth}
  s.description = %q{Abstract XAuth strategy for OmniAuth}

  s.rubyforge_project = "omniauth-xauth"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'omniauth'
  s.add_runtime_dependency 'oauth'
  s.add_runtime_dependency 'multi_json'
end
