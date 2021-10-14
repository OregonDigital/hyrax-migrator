# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare the checksums from the source asset and the migrated asset
  class VerifyChecksumsService < VerifyService
    ALGORITHM = 'MD5hex'

    ## Hyrax already calculates checksum using MD5hex
    def new_content_checksum
      @migrated_work.asset.file_sets.first.original_file.original_checksum.first
    rescue StandardError
      @errors << 'Unable to load migrated checksum'
    end

    def original_checksums
      @original_checksums ||= YAML.load_file(File.join(@migrated_work.working_directory, "data/#{@migrated_work.asset.id}_checksums.yml"))
    rescue StandardError
      @errors << 'Unable to load exported checksum'
    end

    def verify
      @errors = []
      return @errors if @migrated_work.model_name.to_s == 'Generic'

      @errors << "Unable to verify #{ALGORITHM} checksums for #{@migrated_work.asset.id}." unless original_checksums['checksums'][ALGORITHM].first == new_content_checksum
      @errors
    rescue StandardError
      @errors
    end
  end
end
