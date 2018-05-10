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

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = "sanctum"
  spec.require_paths = ["lib"]

  spec.add_dependency 'vault', '~> 0'
  spec.add_dependency 'hashdiff', '~> 0'
  spec.add_dependency 'gli', '~> 2'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
