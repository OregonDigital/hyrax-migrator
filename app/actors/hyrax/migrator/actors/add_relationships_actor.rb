# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Add relationships between parent and children in the Hyrax backend
  class AddRelationshipsActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :add_relationships_initial, initial: true
      state :add_relationships_succeeded, :add_relationships_failed

      event :add_relationships_initial do
        transitions from: %i[add_relationships_initial add_relationships_failed],
                    to: :add_relationships_initial
      end
      event :add_relationships_failed, after: :post_fail do
        transitions from: :add_relationships_initial,
                    to: :add_relationships_failed
      end
      event :add_relationships_succeeded, after: :post_success do
        transitions from: :add_relationships_initial,
                    to: :add_relationships_succeeded
      end
    end

    ##
    # Use the AddRelationshipsService to create the work in Hyrax.
    def create(work)
      super
      add_relationships_initial
      update_work(aasm.current_state)
      service.add_relationships ? add_relationships_succeeded : add_relationships_failed
    rescue StandardError => e
      add_relationships_failed
      log("failed while adding relationships work: #{e.message}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::AddRelationshipsService.new(@work, user)
    end
    #:nocov:

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed adding relationships between parent and children.", Hyrax::Migrator::Work::FAIL)
    end

    def post_success
      succeeded(aasm.current_state, "Work #{@work.pid} added relationships between parent and children.", Hyrax::Migrator::Work::SUCCESS)
    end
  end
end
