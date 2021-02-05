# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  # A service to verify that a cpd's children were successfully attached
  class VerifyChildrenService < VerifyService
    def children
      @migrated_work.asset.ordered_member_ids
    end

    def verify
      return [] if @migrated_work.original_profile['contents'].blank?

      return [] if compare

      find_error
    end

    def compare
      @migrated_work.original_profile['contents'] == children
    end

    def find_error
      return find_missing_children unless size_equal?

      find_order_error
    end

    def find_order_error
      @migrated_work.original_profile['contents'].each_with_index do |pid, index|
        return ["#{children[index]} is out of order"] if children[index] != pid
      end
    end

    def size_equal?
      return false if children.include? nil

      @migrated_work.original_profile['contents'].size == children.size
    end

    def find_missing_children
      errors = []
      @migrated_work.original_profile['contents'].each do |pid|
        errors << "#{pid} missing;" unless children.include? pid
      end
      errors
    end
  end
end
