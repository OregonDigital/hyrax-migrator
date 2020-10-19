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
      update_work(aasm.current_state)
      service.persist_work ? persist_work_succeeded : persist_work_failed
    rescue StandardError => e
      persist_work_failed
      errors(message(e))
      log("error while persisting work: #{e.message} : #{e.backtrace}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::PersistWorkService.new(@work, user)
    end
    #:nocov:

    def message(err)
      message = "error while persisting work: #{err.message}"
      message += ', work persisted' if Hyrax::Migrator::HyraxCore::Asset.exists?(@work.pid)
      message
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed publishing to the repository.", Hyrax::Migrator::Work::FAIL)
    end

    def post_success
      succeeded(aasm.current_state, "Work #{@work.pid} published to the repository.", Hyrax::Migrator::Work::SUCCESS)
    end
  end
end
