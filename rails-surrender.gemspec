# frozen_string_literal: true

require_relative 'lib/rails/surrender/version'

Gem::Specification.new do |s|
  s.name = 'rails-surrender'
  s.version = Rails::Surrender::VERSION
  s.summary = 'JSON rendering for Rails API'
  s.description = 'Lets API clients shape JSON responses with query parameters for include, exclude, filter, ' \
                  'sort, pagination, counts and id lists, while eager loading to avoid N+1 queries.'
  s.authors = ['Shawn McBride']
  s.email = 'smmcbride@gmail.com'
  s.require_paths = ['lib']
  s.files = Dir['lib/**/*', 'CHANGELOG.md', 'LICENSE', 'README.md']
  s.homepage = 'https://github.com/smmcbride/rails-surrender'
  s.license = 'GPL-3.0-only'
  s.required_ruby_version = '>= 3.3'
  s.add_dependency 'actionpack', '>= 8.0', '< 9'
  s.add_dependency 'activerecord', '>= 8.0', '< 9'
  s.add_dependency 'kaminari', '~> 1.2'
  s.add_dependency 'oj', '~> 3.13'
  s.add_dependency 'railties', '>= 8.0', '< 9'
  s.metadata = {
    'changelog_uri' => 'https://github.com/smmcbride/rails-surrender/blob/main/CHANGELOG.md',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/smmcbride/rails-surrender'
  }
end
