# frozen_string_literal: true

require_relative 'lib/fluent/plugin/http_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-http-client'
  spec.version       = Fluent::Plugin::HttpClient::VERSION
  spec.authors       = ['Thomas Tych']
  spec.email         = ['thomas.tych@gmail.com']

  spec.summary       = 'http client for fluentd'
  spec.description   = 'http client for fluentd, based on faraday 2'
  spec.homepage      = 'https://gitlab.com/ttych/fluent-plugin-http-client'
  spec.license       = 'Apache-2.0'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"

  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bump', '~> 0.10.0'
  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'byebug', '~> 11.1', '>= 11.1.1'
  spec.add_development_dependency 'flay', '~> 2.13'
  spec.add_development_dependency 'flog', '~> 4.6', '>= 4.6.6'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'reek', '~> 6.1', '>= 6.1.0'
  spec.add_development_dependency 'rubocop', '~> 1.33', '>= 1.33.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.add_development_dependency 'test-unit', '~> 3.3.4'

  spec.add_runtime_dependency 'faraday', '~> 2.5', '>= 2.0.1'
  spec.add_runtime_dependency 'faraday-retry', '~> 2.0'
  spec.add_runtime_dependency 'fluentd', ['>= 0.14.10', '< 2']
end
