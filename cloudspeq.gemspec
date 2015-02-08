# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudspeq/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudspeq"
  spec.version       = Cloudspeq::VERSION
  spec.authors       = ["Russell Jennings"]
  spec.email         = ["violentpurr@gmail.com"]
  spec.summary       = %q{Distribute your tests in the cloud for faster development in slow test suits}
  spec.description   = %q{Having a slow test suite sucks. But don't let a slow test suite slow you down! with cloudspeq you can distribute your tests and dramatically reduce the time it takes to test.}
  spec.homepage      = "https://github.com/meesterdude/cloudspeq"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'escort', "~> 0.4"
  spec.add_dependency 'digitalocean', "~> 1.2"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.executables << 'cloudspeq'
end
