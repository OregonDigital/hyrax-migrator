# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    ##
    # Allows the migrator to confirm that a given asset has been ingested.
    class Asset
      # :nocov:
      def self.exists?(id)
        ActiveFedora::Base.exists?(id)
      end

      def self.update_field(id, field, new_value)
        asset = Hyrax::Migrator::HyraxCore::Asset.find(id)
        asset.send(field, new_value)
        asset.save!
      end

      def self.solr_record(id)
        ActiveFedora::SolrService.query("id:#{id}", rows: 1).first || []
      end

      def self.find(id)
        ActiveFedora::Base.find(id)
      rescue ActiveFedora::ObjectNotFoundError
        nil
      end
      # :nocov:
    end
  end
end
