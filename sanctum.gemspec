# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sanctum/version'

Gem::Specification.new do |spec|
  spec.name          = 'sanctum'
  spec.version       = Sanctum::VERSION
  spec.authors       = ['Corban Raun']
  spec.email         = ['corban@raunco.co']
  spec.date          = Time.now.strftime('%Y-%m-%d')

  spec.summary       = 'Simple and secure filesystem-to-Vault secrets synchronization'
  spec.description   = 'Syncs encrypted content from the filesystem to the Vault secrets store.'
  spec.homepage      = 'https://github.com/CorbanR/sanctum'
  spec.license       = 'MIT'
  spec.metadata      = { 'documentation_uri' => 'https://github.com/CorbanR/sanctum' }
  spec.required_ruby_version = '>=2.5.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    exclude = [%r{^(test|spec|features|examples|tmp|coverage|cache)/}, %r{docker.*}i, %r{\.nix}, %r{\.gitlab-ci.yml}]
    f.match(Regexp.union(exclude))
  end

  spec.bindir        = 'bin'
  spec.executables   = 'sanctum'
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 6.0'
  spec.add_dependency 'gli', '~> 2.18'
  spec.add_dependency 'hashdiff', ['>= 1.0.0.beta1', '< 2.0.0']
  spec.add_dependency 'tty-editor', '~> 0.5'
  spec.add_dependency 'vault', '~> 0.13'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'overcommit', '~> 0.48'
  spec.add_development_dependency 'pry', '~> 0.13.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.80.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.5.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.38.0'
  spec.add_development_dependency 'simplecov', '~> 0.17'
  spec.add_development_dependency 'yard', '~> 0.9'
end
