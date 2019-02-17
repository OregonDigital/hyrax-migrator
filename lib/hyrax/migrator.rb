# frozen_string_literal:true

# configuration comes first
require 'hyrax/migrator/configuration'

require 'haml'
require 'sidekiq'
require 'hyrax/migrator/engine' if defined?(Rails)
require 'hyrax/migrator/middleware'
require 'hyrax/migrator/hyrax_core/actor_stack'
require 'hyrax/migrator/hyrax_core/user'
require 'hyrax/migrator/hyrax_core/uploaded_file'
require 'hyrax/migrator/hyrax_core/user'

module Hyrax
  ##
  # Hyrax Migrator module configuration
  module Migrator
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Configuration
    end

    # @api public
    #
    # Exposes the Hyrax Migrator configuration
    #
    # @yield [Hyrax::Migrator::Configuration] if a block is passed
    # @return [Hyrax::Migrator::Configuration]
    # @see Hyrax::Migrator::Configuration for options
    def self.config(&block)
      @config ||= Hyrax::Migrator::Configuration.new

      yield @config if block

      @config
    end
  end
end
