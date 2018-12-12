# frozen_string_literal:true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'hyrax/migrator/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'hyrax-migrator'
  s.version     = Hyrax::Migrator::VERSION
  s.authors     = ['']
  s.email       = ['']
  s.homepage    = ''
  s.summary     = 'Summary of Hyrax::Migrator.'
  s.description = 'Description of Hyrax::Migrator.'
  s.license     = 'MIT'

  s.files = Dir[
    '{app,config,db,lib}/**/*',
    'MIT-LICENSE',
    'Rakefile',
    'README.md']

  s.add_dependency 'haml'
  s.add_dependency 'rails', '~> 5.1.6'

  s.add_development_dependency 'puma'
  s.add_development_dependency 'rspec-rails', '~> 3.8'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'sqlite3'
end
