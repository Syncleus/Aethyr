# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require './lib/aethyr/app_info'

Gem::Specification.new do |spec|
  spec.name = 'aethyr'
  spec.version = Aethyr::VERSION
  spec.licenses = ['Apache-2.0']
  spec.authors = ['Jeffrey Phillips Freeman']
  spec.email = ['the@jeffreyfreeman.me']

  spec.summary = %q{The Aethyr MUD Server.}
  spec.description = %q{The Aethyr MUD Server.}
  spec.homepage = 'http://jeffreyfreeman.me'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
      spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
      raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(tests|test|spec|features|integration|logs|storage|build|.bundle|tmp)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'wisper', '~> 2.0'
  spec.add_dependency 'methadone', '~> 2.0'
  spec.add_dependency 'eventmachine', '~> 1.2'
  spec.add_dependency 'require_all', '~> 2.0'
  spec.add_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_dependency 'ncursesw', '~> 1.4'
  spec.add_dependency 'gdbm', '~> 2.1'
  spec.add_dependency 'base64', '~> 0.2'
  spec.add_dependency 'logger', '~> 1.5'
  spec.add_runtime_dependency 'gdal', '~> 3.0'
  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'json', '~> 2.11'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'rdoc', '~> 4.2'
  spec.add_development_dependency 'aruba', '~> 0.14'
  spec.add_development_dependency 'rubocop', '~> 0.82'
  spec.add_development_dependency 'test-unit', '~> 3.5'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov-console', '~> 0.9'
  spec.add_development_dependency 'cucumber', '~> 9.2'
  spec.add_development_dependency 'ruby-prof', '~> 1.7'
end
