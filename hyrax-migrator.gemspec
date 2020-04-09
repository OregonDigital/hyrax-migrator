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

  s.add_dependency 'aasm'
  s.add_dependency 'actionview', '>= 5.1.6.2'
  s.add_dependency 'aws-sdk-s3'
  s.add_dependency 'bagit'
  s.add_dependency 'haml'
  s.add_dependency 'rails', '~> 5.1.6'
  s.add_dependency 'rdf'
  s.add_dependency 'rubyzip'
  s.add_dependency 'sidekiq'

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'coveralls', '~> 0.8'
  s.add_development_dependency 'factory_bot_rails'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'puma'
  s.add_development_dependency 'rspec-rails', '~> 3.8'
  s.add_development_dependency 'rspec_junit_formatter'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'simplecov', '>= 0.9'
  s.add_development_dependency 'sqlite3'
end
