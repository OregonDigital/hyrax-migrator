# frozen_string_literal:true

module Hyrax::Migrator::Services
  # A service to verify that the asset's visibility is correctly assigned
  class VerifyVisibilityService < VerifyService
    include Hyrax::Migrator::VisibilityMethods
    def verify
      return 'visibility error' if lookup(@migrated_work.original_profile['visibility'])[:visibility] != @migrated_work.asset.visibility

      ''
    rescue StandardError
      'visibility error'
    end
  end
end
