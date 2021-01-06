# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare the checksums from the source asset and the migrated asset
  class VerifyChecksumsService
    def initialize(hyrax_asset, profile_dir)
      @hyrax_asset = hyrax_asset
      @profile_dir = profile_dir
      @new_profile = new_profile
      @errors = []
    end

    def content
      fs = @hyrax_asset.file_sets.first
      @content = fs.blank? ? '' : fs.original_file.content
    end

    def new_profile
      result_hash = {}
      result_hash[:checksums] = checksums
      result_hash
    end

    def checksums
      checksums = {}
      checksums['SHA1hex'] = Digest::SHA1.hexdigest content
      checksums['SHA1base64'] = Digest::SHA1.base64digest content
      checksums['MD5hex'] = Digest::MD5.hexdigest content
      checksums['MD5base64'] = Digest::MD5.base64digest content
      checksums
    end

    def original_checksums
      @original_checksums ||= YAML.load_file(File.join(@profile_dir, "#{@hyrax_asset.id}_checksums.yml"))
    rescue StandardError
      @original_checksums = {}
    end

    def verify_content
      return [] if original_checksums['checksums'].blank?

      original_checksums['checksums'].each do |key, val|
        next if val.blank?

        @errors << "Content does not match precomputed #{key} checksums for #{@hyrax_asset.id}." unless val.first == @new_profile[:checksums][key]
      end
      @errors
    end
  end
end
