# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'rails/surrender/version'

Gem::Specification.new do |s|
  s.name = 'rails-surrender'
  s.version = Rails::Surrender::VERSION
  s.date = '2021-12-22'
  s.summary = 'JSON rendering for Rails API'
  s.authors = ['Shawn McBride']
  s.email = 'smmcbride@gmail.com'
  s.require_paths = ['lib']
  s.files = Dir['{lib,test}/**/*']
  s.homepage = 'https://github.com/smmcbride/rails-surrender'
  s.license = 'GPL-3.0'
  s.add_dependency 'kaminari', ['= 1.2.1']
  s.add_dependency 'oj', ['= 3.13.10']
  s.required_ruby_version = '~> 3.0'
end
