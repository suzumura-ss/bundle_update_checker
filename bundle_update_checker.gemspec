# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bundle_update_checker/version'

Gem::Specification.new do |spec|
  spec.name          = "bundle_update_checker"
  spec.version       = BundleUpdateChecker::VERSION
  spec.authors       = ["Toshiyuki Suzumura"]
  spec.email         = ["suz.labo@smoche.sakuraweb.com"]

  spec.summary       = %q{Try bundle update for each gems.}
  spec.description   = %q{Try bundle update for each gems.}
  spec.homepage      = "https://bitbucket.org/pflabo/bundle_update_checker"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "thor"
  spec.add_dependency "json"
end
