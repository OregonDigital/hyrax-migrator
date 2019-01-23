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

    def create(work)
      super
      model_lookup_initial
      update_work
      @work.env[:model] = service.model
      model_lookup_succeeded
    rescue StandardError => e
      model_lookup_failed
      log("failed during model lookup: #{e.message}")
    end

    private

    def service
      @service ||= ModelLookupService.new(@work, config)
    end

    def post_fail
      update_work
    end

    def post_success
      update_work
      call_next_actor
    end

    def update_work
      @work.aasm_state = aasm.current_state
      @work.save
    end
  end
end
