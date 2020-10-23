# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  # A service to verify that a cpd's children were successfully attached
  class VerifyChildrenService
    def initialize(migrator_work, hyrax_asset, original_profile, config = Hyrax::Migrator.config)
      @migrator_work = migrator_work
      @hyrax_asset = hyrax_asset
      @original_profile = original_profile
      @config = config
      @errors = verify_children
    end

    def children
      @hyrax_asset.ordered_member_ids
    end

    def verify_children
      return [] if @original_profile['contents'].blank?

      errors = verify_children_present
      return errors unless errors.empty?

      verify_children_order
    end

    def verify_children_order
      @original_profile['contents'].each_with_index do |pid, index|
        clean_pid = pid.strip.gsub('oregondigital:', '')
        return ["#{children[index]} is out of order"] if children[index] != clean_pid
      end
      []
    end

    def verify_children_present
      errors = []
      @original_profile['contents'].each do |pid|
        clean_pid = pid.strip.gsub('oregondigital:', '')
        errors << "#{clean_pid} missing;" unless children.include? clean_pid
      end
      errors
    end
  end
end
