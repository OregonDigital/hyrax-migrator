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

    # The crosswalk file for looking up a model related to the metadata type URI for a work.
    # The model should match one that is found in the models configuration for this engine.
    #
    # For example, the following lines in the hyrax_migrator initializer will include
    # reference to the Image and Generic models found in the MyApp::Models namespace
    #
    # config.register_model MyApp::Models::Image
    # config.register_model MyApp::Models::Generic
    attr_writer :model_crosswalk
    def model_crosswalk
      @model_crosswalk ||= ''
    end
  end
end
