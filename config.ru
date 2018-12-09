# frozen_string_literal:true

require 'rubygems'
require 'bundler'
require 'rails'
Bundler.require(:default)
run Hyrax::Migrator::Engine
