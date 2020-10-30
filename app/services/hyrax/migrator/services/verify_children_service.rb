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

      return [] if compare

      find_error
    end

    def compare
      @original_profile['contents'] == children
    end

    def find_error
      return find_missing_children unless size_equal?

      find_order_error
    end

    def find_order_error
      @original_profile['contents'].each_with_index do |pid, index|
        return ["#{children[index]} is out of order"] if children[index] != pid
      end
    end

    def size_equal?
      @original_profile['contents'].size == children.size
    end

    def find_missing_children
      errors = []
      @original_profile['contents'].each do |pid|
        errors << "#{pid} missing;" unless children.include? pid
      end
      errors
    end
  end
end
