# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Add permissions to collections that are already persisted.
  class AddCollectionPermissionActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :add_collection_permission_initial, initial: true
      state :add_collection_permission_succeeded, :add_collection_permission_failed

      event :add_collection_permission_initial do
        transitions from: %i[add_collection_permission_initial add_collection_permission_failed],
                    to: :add_collection_permission_initial
      end
      event :add_collection_permission_failed, after: :post_fail do
        transitions from: :add_collection_permission_initial,
                    to: :add_collection_permission_failed
      end
      event :add_collection_permission_succeeded, after: :post_success do
        transitions from: :add_collection_permission_initial,
                    to: :add_collection_permission_succeeded
      end
    end

    HAS_CHILD = 'Collection Permission added.'
    NO_CHILD = 'No Collection Permission to add.'

    ##
    # Use the PermissionsCreateService to add permissions to collections in Hyrax.
    def create(work)
      super
      if !work.collection?
        @message = NO_CHILD
        add_collection_permission_succeeded
      else
        call_service
      end
    rescue StandardError => e
      add_collection_permission_failed
      log("failed while adding collection permission to collection work: #{e.message}")
    end

    private

    def call_service
      @message = HAS_CHILD
      add_collection_permission_initial
      update_work(aasm.current_state)
      service ? add_collection_permission_succeeded : add_collection_permission_failed
    end

    #:nocov:
    def service
      @service ||= Hyrax::Collections::PermissionsCreateService.add_access(collection_id: @work.id, grants: [{agent_type: Hyrax::PermissionTemplateAccess::USER, 
                                                                                                              agent_id: @user.user_key, 
                                                                                                              access: Hyrax::PermissionTemplateAccess::MANAGE }])
    end
    #:nocov:

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed adding collection permission.", Hyrax::Migrator::Work::FAIL)
    end

    def post_success
      succeeded(aasm.current_state, "Work #{@work.pid} #{@message}", Hyrax::Migrator::Work::SUCCESS)
    end
  end
end

