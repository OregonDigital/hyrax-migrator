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
    # Pass the user, model, and attributes to the Hyrax integration class
    # to cause it to persist the work.
    #
    # returns [Boolean] true if the works saved, false if it failed
    def persist_work
      actor_stack.create
    rescue StandardError => e
      message = "failed persisting work #{@work.pid}, #{e.message}"
      Rails.logger.error message
      raise StandardError, message
    end

    private

    def actor_stack
      @actor_stack ||= Hyrax::Migrator::HyraxCore::ActorStack.new(
        migration_user: @config.migration_user,
        model: @work.env[:model],
        attributes: attributes
      )
    end

    def attributes
      @work.env[:attributes].merge(id: @work.pid)
    end
  end
end
