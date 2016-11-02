# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_manager/version'

Gem::Specification.new do |spec|
  spec.name          = 'aws_manager'
  spec.version       = AwsManager::VERSION
  spec.authors       = ['Anirvan Chakraborty']
  spec.email         = ['anirvanc@cakesolutions.net']
  spec.description   = spec.summary
  spec.summary       = 'AwsManager is a toolkit for interacting with AWS resources using the Ruby AWS SDK.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0.19.1'
  spec.add_dependency 'aws-sdk', '~> 2.0.45'
  spec.add_dependency 'system-getifaddrs', '~> 0.2.1'
  spec.add_dependency 'diffy', '~> 3.0.7'
  spec.add_dependency 'hiera', '~> 3.1.2'
  spec.add_dependency 'puppet', '~> 4.4.2'
  spec.add_dependency 'table_print', '~> 1.5.6'
  spec.add_dependency 'colorize', '~> 0.8.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
