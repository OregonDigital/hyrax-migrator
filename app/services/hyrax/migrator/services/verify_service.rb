# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Create report on facet values for migrated batch of assets
  class VerifyService
    def initialize(migrated_work)
      @migrated_work = migrated_work
    end

    def verify; end
  end
end
