# frozen_string_literal: true

require 'rdf'

module Hyrax::Migrator::Services
  # A service to pull ids out of set-related fields for admin_set and collection memberships
  class AdminSetMembershipService
    PRIMARY_SET_PREDICATE = 'http://opaquenamespace.org/ns/primarySet'
    SET_PREDICATE = 'http://opaquenamespace.org/ns/set'
    INSTITUTION_PREDICATE = 'http://opaquenamespace.org/ns/contributingInstitution'

    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
      @data_dir = File.join(work.working_directory, 'data')
      @graph = create_graph
    end

    def acquire_set_ids
      result = {}
      result['ids'] = {
        admin_set_id: admin_set_id,
        member_of_collections_attributes: collection_ids
      }
      result['metadata_set'] = metadata_set
      result['metadata_primary_set'] = metadata_primary_set
      result['metadata_institution'] = metadata_institution
      result
    end

    private

    def admin_set_id
      return admin_set_id_from_primary_set(metadata_primary_set) if metadata_primary_set.present?

      return admin_set_id_from_institution(metadata_institution) if metadata_institution.present?

      log_and_raise("Primary Set and Institution not found for #{@work.pid}")
    end

    def log_and_raise(message)
      Rails.logger.warn(message)
      raise StandardError, message
    end

    def create_graph
      Hyrax::Migrator::Services::CreateGraphService.call(@data_dir)
    end

    def collection_ids
      result = {}
      return result if metadata_set.blank?

      metadata_set.each_with_index do |s, index|
        result[index.to_s] = { 'id' => strip_id(s) }
      end
      result
    end

    def metadata_primary_set
      primary_set = @graph.statements.detect { |s| s.predicate.to_s.casecmp(PRIMARY_SET_PREDICATE).zero? }
      primary_set.object.to_s if primary_set.present?
    end

    def metadata_institution
      institution = @graph.statements.detect { |s| s.predicate.to_s.casecmp(INSTITUTION_PREDICATE).zero? }
      institution.object.to_s if institution.present?
    end

    def metadata_set
      @graph.statements.select { |s| s.predicate.to_s.casecmp(SET_PREDICATE).zero? }.map { |r| r.object.to_s }
    end

    def admin_set_id_from_primary_set(uri)
      primary_set_id = strip_id(uri)
      id = match_primary_set(primary_set_id)
      id.present? ? Hyrax::Migrator::HyraxCore::AdminSet.find(id).id : log_and_raise('Primary Set/Admin Set mapping failed')
    end

    def admin_set_id_from_institution(uri)
      id = match_institution(uri)
      id.present? ? Hyrax::Migrator::HyraxCore::AdminSet.find(id).id : log_and_raise('Institution/Admin Set mapping failed')
    end

    # Returns a data list that maps OD1 primary sets and institutions to OD2 amdin sets
    def crosswalk_data
      @crosswalk_data ||= YAML.load_file(@config.crosswalk_admin_sets_file).deep_symbolize_keys
    end

    def match_primary_set(primary_set_id)
      hash_match = crosswalk_data[:primary_set_crosswalk].detect { |data| data[:primary_set] == primary_set_id }
      hash_match[:admin_set_id] if hash_match.present?
    end

    def match_institution(uri)
      hash_match = crosswalk_data[:institution_crosswalk].detect { |data| data[:institution_uri] == uri }
      hash_match[:admin_set_id] if hash_match.present?
    end

    def strip_id(uri)
      uri.to_s.split('/').last.gsub('oregondigital:', '')
    end
  end
end
