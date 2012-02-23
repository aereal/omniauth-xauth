# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth-xauth/version', __FILE__)

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

  s.add_runtime_dependency     'omniauth', '~> 1.0'
  s.add_runtime_dependency     'oauth'
  s.add_development_dependency 'rspec', '~> 2.8'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rack-test'
end
