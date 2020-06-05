# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare various elements from the source asset and the migrated asset
  class VerificationService
    def initialize(migrator_work, migrator_config, profile_dir = nil)
      @work = migrator_work
      @profile_dir = profile_dir.nil? ? File.join(@work.working_directory, 'data') : profile_dir
      @config = migrator_config
      @metadata_service = Hyrax::Migrator::Services::VerifyMetadataService.new(@work, @config, hyrax_asset, original_profile)
      @checksums_service = Hyrax::Migrator::Services::VerifyChecksumsService.new(@work, hyrax_asset, original_profile)
      @derivatives_service = Hyrax::Migrator::Services::VerifyDerivativesService.new(hyrax_asset, original_profile)
    end

    def hyrax_asset
      @hyrax_asset ||= Hyrax::Migrator::HyraxCore::Asset.find(@work.pid)
    end

    def verify
      errors = []
      errors << @metadata_service.verify_metadata
      errors << @checksums_service.verify_content
      errors << @derivatives_service.verify
      errors
    rescue StandardError => e
      errors << "Encountered an error while working on #{@work.pid}: #{e.message}"
    end

    def original_profile
      @original_profile ||= YAML.load_file(File.join(@profile_dir, "#{@work.pid}_profile.yml"))
    end
  end
end
