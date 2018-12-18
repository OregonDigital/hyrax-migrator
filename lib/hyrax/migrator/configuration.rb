# frozen_string_literal:true

module Hyrax::Migrator
  ##
  # The main hyrax migrator configuration!
  class Configuration
    def initialize
      @registered_models = []
    end

    def register_model(*models)
      Array.wrap(models).flatten.compact.each do |m|
        @registered_models << m unless @registered_models.include? m
      end
    end

    def models
      @registered_models
    end

    # The path to automatically mount the migrator engine to, or setting to false will prevent automatic mounting.
    attr_writer :mount_at
    def mount_at
      @mount_at ||= 'migrator'
    end

    # The background job queue name, defaults to 'hyrax_migrator'
    attr_writer :queue_name
    def queue_name
      @queue_name ||= 'hyrax_migrator'
    end

    # The logger to use for logging
    attr_writer :logger
    def logger
      @logger ||= Logger.new nil
    end
  end
end
