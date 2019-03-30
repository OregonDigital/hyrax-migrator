# frozen_string_literal: true

require 'rdf'

module Hyrax::Migrator::Services
  # A service to pull ids out of set-related fields for admin_set and collection memberships
  class AdminSetMembershipService
    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
    end

    def acquire_set_ids
      result = {}
      result['admin_set_id'] = admin_set(@work.env[:attributes])
      result['member_of_collections_attributes'] = collection_ids(@work.env[:attributes])
      result
    end

    private

    def admin_set(metadata)
      return strip_id(metadata[:primary_set]) if metadata[:primary_set]

      return strip_id(metadata[:institution].first) if metadata[:institution]

      return strip_id(metadata[:repository].first) if metadata[:repository]

      'admin/default'
    end

    def collection_ids(metadata)
      result = {}
      return result if metadata[:set].blank?

      metadata[:set].each_with_index do |s, index|
        result[index.to_s] = { 'id' => strip_id(s) }
      end
      result
    end

    def strip_id(uri)
      uri.to_s.split('/').last.gsub('oregondigital:', '')
    end
  end
end
