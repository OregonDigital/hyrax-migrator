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
      update_work
      cms = Hyrax::Migrator::Services::CrosswalkMetadataService.new(work, config)
      @hash = cms.crosswalk
      @hash ? crosswalk_metadata_succeeded : crosswalk_metadata_failed
    rescue StandardError => e
      crosswalk_metadata_failed
      log("failed crosswalk: #{e.message}")
    end

    private

    def post_success
      @work.env[:crosswalk_metadata] = @hash
      update_work
      call_next_actor
    end

    def post_fail
      update_work
    end

    def update_work
      @work.aasm_state = aasm.current_state
      @work.save
    end
  end
end
