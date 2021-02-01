# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    # Provide facet query for administrative use
    class UnreviewedSearchBuilder < Blacklight::SearchBuilder
      attr_accessor :properties, :collection_id
      self.default_processor_chain = [:show_unreviewed_facets]
      # :nocov:
      def show_unreviewed_facets(solr_parameters)
        solr_parameters[:'facet.field'] = [properties]
        solr_parameters[:q] = "member_of_collection_ids_ssim:#{collection_id} AND workflow_state_name_ssim:pending_review"
        solr_parameters[:rows] = 0
      end
      # :nocov:
    end
  end
end
