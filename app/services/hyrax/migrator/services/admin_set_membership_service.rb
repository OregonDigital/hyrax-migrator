# frozen_string_literal: true

require 'rdf'

module Hyrax::Migrator::Services
  # A service to pull ids out of set-related fields for admin_set and collection memberships
  class AdminSetMembershipService
    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
    end

    def get_set_ids
      result = {}
      result[:admin_set_id] = admin_set(@work.env[:crosswalk_metadata])
      result[:collection_ids] = coll_ids(@work.env[:crosswalk_metadata])
      result
    end

    private

    def admin_set(metadata)
      return strip_id(metadata[:primarySet]) if metadata[:primarySet]

      return strip_id(metadata[:institution].first) if metadata[:institution]

      return strip_id(metadata[:repository].first) if metadata[:repository]

      'admin/default'
    end

    def coll_ids(metadata)
      result = []
      return result if metadata[:set].blank?

      metadata[:set].each do |s|
        result << strip_id(s)
      end
      result
    end

    def strip_id(uri)
      uri.to_s.split('/').last.gsub('oregondigital:', '')
    end
  end
end
