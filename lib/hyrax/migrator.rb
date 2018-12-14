# frozen_string_literal:true

# configuration comes first
require 'hyrax/migrator/configuration'

require 'haml'
require 'hyrax/migrator/engine' if defined?(Rails)
require 'hyrax/migrator/middleware'

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
