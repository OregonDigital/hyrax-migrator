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
      @attributes = Hyrax::Migrator::Services::CrosswalkMetadataService.new(work, config).crosswalk
      @attributes ? crosswalk_metadata_succeeded : crosswalk_metadata_failed
    rescue StandardError => e
      crosswalk_metadata_failed
      log("failed crosswalk: #{e.message} : #{e.backtrace}")
    end

    # update overwrites work attributes, will leave the work attributes empty if no changes were found
    def update(work)
      super
      @attributes = promote_changes
      @attributes ? crosswalk_metadata_succeeded : crosswalk_metadata_failed
    end

    private

    def promote_changes
      attributes = Hyrax::Migrator::Services::CrosswalkMetadataService.new(work, config).crosswalk
      attributes.each do |key, val|
        attributes.delete key unless test(key, val)
      end
    rescue StandardError => e
      crosswalk_metadata_failed
      log("failed crosswalk: #{e.message} : #{e.backtrace}")
    end

    def test(key, val)
      @work.env[:attributes][key].nil? || @work.env[:attributes][key] != val
    end

    def post_success
      @work.env[:errors] = @attributes.delete :errors
      @work.env[:attributes] = @attributes
      succeeded(aasm.current_state, "Work #{@work.pid} crosswalked metadata.", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} crosswalk metadata failed.", Hyrax::Migrator::Work::FAIL)
    end
  end
end
