# frozen_string_literal: true

require 'rdf'

module Hyrax::Migrator::Services
  # A service to pull ids out of set-related fields for admin_set and collection memberships
  class AdminSetMembershipService
    DEFAULT_ADMIN_SET_ID = 'admin/default'

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
      return admin_set_id(metadata[:primary_set]) if metadata[:primary_set]

      return admin_set_id(metadata[:institution].first) if metadata[:institution]

      return admin_set_id(metadata[:repository].first) if metadata[:repository]

      DEFAULT_ADMIN_SET_ID
    end

    def collection_ids(metadata)
      result = {}
      return result if metadata[:set].blank?

      metadata[:set].each_with_index do |s, index|
        result[index.to_s] = { 'id' => strip_id(s) }
      end
      result
    end

    def admin_set_id(uri)
      original_id = strip_id(uri)
      title = admin_set_title(original_id)
      title.present? ? Hyrax::Migrator::HyraxCore::AdminSet.find_by_title(title).id : DEFAULT_ADMIN_SET_ID
    end

    # Returns a data list that maps OD1 primary sets to OD2 amdin sets
    def crosswalk_data
      @crosswalk_data ||= YAML.load_file(@config.crosswalk_admin_sets_file).deep_symbolize_keys
      @crosswalk_data[:crosswalk]
    end

    def admin_set_title(primary_set_id)
      hash_match = crosswalk_data.detect { |data| data[:primary_set] == primary_set_id }
      hash_match[:admin_set_title] if hash_match.present?
    end

    def strip_id(uri)
      uri.to_s.split('/').last.gsub('oregondigital:', '')
    end
  end
end
