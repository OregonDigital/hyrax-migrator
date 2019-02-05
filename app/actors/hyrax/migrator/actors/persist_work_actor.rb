# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Persist the work in the Hyrax backend
  class PersistWorkActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :persist_work_initial, initial: true
      state :persist_work_succeeded, :persist_work_failed

      event :persist_work_initial do
        transitions from: %i[persist_work_initial persist_work_failed],
                    to: :persist_work_initial
      end
      event :persist_work_failed, after: :post_fail do
        transitions from: :persist_work_initial,
                    to: :persist_work_failed
      end
      event :persist_work_succeeded, after: :post_success do
        transitions from: :persist_work_initial,
                    to: :persist_work_succeeded
      end
    end

    ##
    # Use the PersistWorkService to create the work in Hyrax.
    def create(work)
      super
      persist_work_initial
      update_work
      service.persist_work ? persist_work_succeeded : persist_work_failed
    rescue StandardError => e
      persist_work_failed
      log("failed while persisting work: #{e.message}")
    end

    private

    #:nocov:
    def service
      @service ||= PersistWorkService.new(@work, config)
    end
    #:nocov:

    def post_fail
      @work.status_message = "Work #{work.pid} failed publishing to the repository."
      @work.status = Hyrax::Migrator::Work::FAIL
      update_work
    end

    def post_success
      @work.status_message = "Work #{work.pid} published to the repository."
      @work.status = Hyrax::Migrator::Work::SUCCESS
      update_work
      call_next_actor
    end

    def update_work
      @work.aasm_state = aasm.current_state
      @work.save
    end
  end
end
