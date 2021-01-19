# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare the checksums from the source asset and the migrated asset
  class VerifyChecksumsService
    ALGORITHM = 'MD5hex'

    def initialize(hyrax_asset, profile_dir)
      @hyrax_asset = hyrax_asset
      @profile_dir = profile_dir
    end

    ## Hyrax already calculates checksum using MD5hex
    def new_content_checksum
      @hyrax_asset.file_sets.first.original_file.original_checksum.first
    rescue StandardError
      ''
    end

    def original_checksums
      @original_checksums ||= YAML.load_file(File.join(@profile_dir, "#{@hyrax_asset.id}_checksums.yml"))
    rescue StandardError
      @original_checksums = {}
    end

    def verify_content
      return [] if original_checksums['checksums'].blank?

      return ["Content does not match precomputed #{ALGORITHM} checksums for #{@hyrax_asset.id}."] unless original_checksums['checksums'][ALGORITHM].first == new_content_checksum

      []
    end
  end
end
