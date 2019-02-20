# frozen_string_literal: true

require 'rdf'

module Hyrax::Migrator::Actors
  # Extracts metadata from bag, calls MetadataCrosswalkService
  class CrosswalkMetadataActor < Hyrax::Migrator::Actors::AbstractActor
    include RDF

    aasm do
      state :crosswalk_metadata_initial, initial: true
      state :crosswalk_metadata_succeeded, :crosswalk_metadata_failed

      event :crosswalk_metadata_initial do
        transitions from:
                    %i[crosswalk_metadata_initial crosswalk_metadata_failed],
                    to: :crosswalk_metadata_initial
      end
      event :crosswalk_metadata_failed, after: :post_fail do
        transitions from: :crosswalk_metadata_initial,
                    to: :crosswalk_metadata_failed
      end
      event :crosswalk_metadata_succeeded, after: :post_success do
        transitions from: :crosswalk_metadata_initial,
                    to: :crosswalk_metadata_succeeded
      end
    end

    def create(work)
      super
      crosswalk_metadata_initial
      update_work(aasm.current_state)
      cms = Hyrax::Migrator::Services::CrosswalkMetadataService.new(work, config)
      @attributes = cms.crosswalk
      @attributes ? crosswalk_metadata_succeeded : crosswalk_metadata_failed
    rescue StandardError => e
      crosswalk_metadata_failed
      log("failed crosswalk: #{e.message} : #{e.backtrace}")
    end

    private

    def post_success
      @work.env[:attributes] = @attributes
      succeeded(aasm.current_state, "Work #{@work.pid} crosswalked metadata.", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} crosswalk metadata failed.", Hyrax::Migrator::Work::FAIL)
    end
  end
end
