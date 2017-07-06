# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kashi/version'

Gem::Specification.new do |spec|
  spec.name          = 'kashi'
  spec.version       = Kashi::VERSION
  spec.authors       = ['wata']
  spec.email         = ['wata.gm@gmail.com']

  spec.summary       = %q{Codenize StatusCake}
  spec.description   = %q{Manage StatusCake by DSL}
  spec.homepage      = 'https://github.com/wata-gh/kashi'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'statuscake', '~> 0.1.2'
  spec.add_dependency 'hashie', '~> 3.5', '>= 3.5.5'
  spec.add_dependency 'diffy', '~> 3.2', '>= 3.2.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry-byebug', '~> 3.4'
end
