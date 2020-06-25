# frozen_string_literal: true

require 'rdf'

module Hyrax::Migrator::Actors
  # Lookup additional metadata found in the workflowMetadata file, and update the asset to preserve this information like date_uploaded
  class WorkflowMetadataActor < Hyrax::Migrator::Actors::AbstractActor
    include RDF

    aasm do
      state :workflow_metadata_initial, initial: true
      state :workflow_metadata_succeeded, :workflow_metadata_failed

      event :workflow_metadata_initial do
        transitions from:
                    %i[workflow_metadata_initial workflow_metadata_failed],
                    to: :workflow_metadata_initial
      end
      event :workflow_metadata_failed, after: :post_fail do
        transitions from: :workflow_metadata_initial,
                    to: :workflow_metadata_failed
      end
      event :workflow_metadata_succeeded, after: :post_success do
        transitions from: :workflow_metadata_initial,
                    to: :workflow_metadata_succeeded
      end
    end

    def create(work)
      super
      workflow_metadata_initial
      update_work(aasm.current_state)
      lookup_and_update ? workflow_metadata_succeeded : workflow_metadata_failed
    rescue StandardError => e
      log("failed workflow metadata lookup #{e.message} : #{e.backtrace}")
      workflow_metadata_failed
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::WorkflowMetadataService.new(@work)
    end
    #:nocov:

    def lookup_and_update
      @workflow_profile = service.workflow_profile
      @workflow_profile.present? && service.update_asset
    end

    def post_success
      @work.env[:raw_workflow_metadata_profile] = @workflow_profile
      succeeded(aasm.current_state, "Work #{@work.pid} retrieved metadata from workflowMetadata profile.", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed while retrieving workflowMetadata profile.", Hyrax::Migrator::Work::FAIL)
    end
  end
end
