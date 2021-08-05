# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Persist the work in the Hyrax backend
  class UpdateWorkActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :update_work_initial, initial: true
      state :update_work_succeeded, :update_work_failed

      event :update_work_initial, after: :post_initial do
        transitions from: %i[update_work_initial update_work_failed],
                    to: :update_work_initial
      end
      event :update_work_failed, after: :post_fail do
        transitions from: :update_work_initial,
                    to: :update_work_failed
      end
      event :update_work_succeeded, after: :post_success do
        transitions from: :update_work_initial,
                    to: :update_work_succeeded
      end
    end

    ##
    # Use the UpdateWorkService to create the work in Hyrax.
    def update(work)
      super
      update_work_initial
      service.update_work ? update_work_succeeded : update_work_failed
    rescue StandardError => e
      update_work_failed
      errors(message(e))
      log("error while persisting work: #{e.message} : #{e.backtrace}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::UpdateWorkService.new(@work, user)
    end
    #:nocov:

    def message(err)
      "error while updating work: #{err.message}"
    end

    def exists?
      Hyrax::Migrator::HyraxCore::Asset.exists? @work.pid
    end

    def post_initial
      update_work(aasm.current_state)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed updating.", Hyrax::Migrator::Work::FAIL)
    end

    def post_success
      succeeded(aasm.current_state, "Work #{@work.pid} updated.", Hyrax::Migrator::Work::SUCCESS)
    end
  end
end
