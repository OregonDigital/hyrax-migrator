# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Lookup which model to use for the work
  class ModelLookupActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :model_lookup_initial, initial: true
      state :model_lookup_succeeded, :model_lookup_failed

      event :model_lookup_initial do
        transitions from: %i[model_lookup_initial model_lookup_failed],
                    to: :model_lookup_initial
      end
      event :model_lookup_failed, after: :post_fail do
        transitions from: :model_lookup_initial,
                    to: :model_lookup_failed
      end
      event :model_lookup_succeeded, after: :post_success do
        transitions from: :model_lookup_initial,
                    to: :model_lookup_succeeded
      end
    end

    ##
    # Use the ModelLookupService and configurations to determine what kind
    # of registered model this work will be initialized as when it comes time
    # to create the work in Hyrax.
    def create(work)
      super
      model_lookup_initial
      update_work(aasm.current_state)
      @model = service.model
      model_lookup_succeeded
    rescue StandardError => e
      model_lookup_failed
      log("failed during model lookup: #{e.message} : #{e.backtrace}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::ModelLookupService.new(@work, config)
    end
    #:nocov:

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed to find a model in the lookup.", Hyrax::Migrator::Work::FAIL)
    end

    def post_success
      @work.env[:model] = @model
      succeeded(aasm.current_state, "Work #{@work.pid} found #{@work.env[:model]} in lookup.", Hyrax::Migrator::Work::SUCCESS)
    end
  end
end
