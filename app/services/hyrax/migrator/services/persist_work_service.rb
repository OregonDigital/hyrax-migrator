# frozen_string_literal:true

module Hyrax::Migrator::Services
  ##
  # A service to build and persist the model in Hyrax
  class PersistWorkService
    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
    end

    ##
    # Initialize the model, set its attributes, and save it
    #
    # returns [Boolean] true if the model saved, false if it failed
    def persist_work
      model.attributes = attributes
      model.save
    rescue StandardError => e
      message = "failed persisting work #{@work.pid}, #{e.message}"
      Rails.logger.error message
      raise StandardError, message
    end

    private

    # :nocov:
    def model
      @model ||= @work.env[:model].constantize.new
    end
    # :nocov:

    def attributes
      @work.env[:attributes].merge(id: @work.pid)
    end
  end
end
