# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Lookup which visibility to use for the work
  class VisibilityLookupActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :visibility_lookup_initial, initial: true
      state :visibility_lookup_succeeded, :visibility_lookup_failed

      event :visibility_lookup_initial do
        transitions from: %i[visibility_lookup_initial visibility_lookup_failed],
                    to: :visibility_lookup_initial
      end
      event :visibility_lookup_failed, after: :post_fail do
        transitions from: :visibility_lookup_initial,
                    to: :visibility_lookup_failed
      end
      event :visibility_lookup_succeeded, after: :post_success do
        transitions from: :visibility_lookup_initial,
                    to: :visibility_lookup_succeeded
      end
    end

    def create(work)
      super
      visibility_lookup_initial
      update_work(aasm.current_state)
      @visibility = service.lookup_visibility
      visibility_lookup_succeeded
    rescue StandardError => e
      visibility_lookup_failed
      log("failed during visibility lookup: #{e.message} : #{e.backtrace}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::VisibilityLookupService.new(@work, config)
    end
    #:nocov:

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed to find a group in visibility lookup.", Hyrax::Migrator::Work::FAIL)
    end

    def post_success
      @work.env[:attributes].merge! @visibility
      succeeded(aasm.current_state, "Work #{@work.pid} found #{@work.env[:attributes][:visibility]} in lookup.", Hyrax::Migrator::Work::SUCCESS)
    end
  end
end
