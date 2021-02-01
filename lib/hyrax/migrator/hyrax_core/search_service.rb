# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    # Provides faceted solr search
    class SearchService
      # :nocov:
      def search(coll_id, property)
        search_builder.collection_id = coll_id
        search_builder.properties = property
        repository.search(search_builder)
      end

      def search_builder
        @search_builder ||= UnreviewedSearchBuilder.new(config: blacklight_config, user_params: {})
      end

      def repository
        blacklight_config.repository_class.new(blacklight_config)
      end

      def blacklight_config
        CatalogController.blacklight_config
      end
      # :nocov:
    end
  end
end
