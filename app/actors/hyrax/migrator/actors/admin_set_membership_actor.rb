# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Calls AdminSetMembershipService to get set ids for admin_sets and collections
  class AdminSetMembershipActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :admin_set_membership_initial, initial: true
      state :admin_set_membership_succeeded, :admin_set_membership_failed

      event :admin_set_membership_initial do
        transitions from:
                    %i[admin_set_membership_initial admin_set_membership_failed],
                    to: :admin_set_membership_initial
      end
      event :admin_set_membership_failed, after: :post_fail do
        transitions from: :admin_set_membership_initial,
                    to: :admin_set_membership_failed
      end
      event :admin_set_membership_succeeded, after: :post_success do
        transitions from: :admin_set_membership_initial,
                    to: :admin_set_membership_succeeded
      end
    end

    def create(work)
      super
      admin_set_membership_initial
      update_work(aasm.current_state)
      asms = Hyrax::Migrator::Services::AdminSetMembershipService.new(work, config)
      @hash = asms.acquire_set_ids
      @hash ? admin_set_membership_succeeded : admin_set_membership_failed
    rescue StandardError => e
      admin_set_membership_failed
      log("did not obtain sets: #{e.message} : #{e.backtrace}")
    end

    private

    def post_success
      @work.env[:attributes].merge!(@hash['ids'])
      @work.env[:primary_set] = @hash['metadata_primary_set']
      @work.env[:set] = @hash['metadata_set']
      succeeded(aasm.current_state, "Work #{@work.pid} acquired admin_set_id and any collections.", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed to acquire admin_set_id and/or collections.", Hyrax::Migrator::Work::FAIL)
    end
  end
end
