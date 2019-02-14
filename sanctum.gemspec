lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sanctum/version'

Gem::Specification.new do |spec|
  spec.name          = "sanctum"
  spec.version       = Sanctum::VERSION
  spec.authors       = ["Corban Raun"]
  spec.email         = ["corban@raunco.co"]
  spec.date          = Time.now.strftime('%Y-%m-%d')

  spec.summary       = %q{Simple and secure filesystem-to-Vault secrets synchronization}
  spec.description   = %q{Syncs encrypted content from the filesystem to the Vault secrets store.}
  spec.homepage      = "https://github.com/CorbanR/sanctum"
  spec.license       = "MIT"
  spec.metadata      = {"documentation_uri" => "https://github.com/CorbanR/sanctum"}
  spec.required_ruby_version = '>=2.5.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = "sanctum"
  spec.require_paths = ["lib"]

  spec.add_dependency 'vault', '~> 0.12'
  spec.add_dependency 'hashdiff', '~> 0.3'
  spec.add_dependency 'gli', '~> 2.18'

  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency 'pry', '~> 0.12.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.63.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.32.0'
end
