# frozen_string_literal:true

require 'hyrax/migrator/middleware/default_middleware'

module Hyrax
  module Migrator
    ##
    # The migrator middleware for processing actors on a work being migrated.
    module Middleware
      extend ActiveSupport::Autoload

      eager_autoload do
        autoload :Configuration
      end

      # @api public
      #
      # Exposes the Hyrax Migrator middleware configuration
      #
      # @yield [Hyrax::Migrator::Middleware::Configuration] if a block is passed
      # @return [Hyrax::Migrator::Middleware::Configuration]
      # @see Hyrax::Migrator::Middleware::Configuration for options
      def self.config(&block)
        @config = Hyrax::Migrator::Middleware::Configuration.new

        yield @config if block

        @config
      end

      ##
      # Provide the default middleware initialized with the actor_stack from configuration
      # @return [Hyrax::Migrator::Middleware::DefaultMiddleware]
      def self.default
        Hyrax::Migrator::Middleware::DefaultMiddleware.new(config.actor_stack)
      end

      def self.custom(config)
        Hyrax::Migrator::Middleware::DefaultMiddleware.new(config.actor_stack)
      end
    end
  end
end
