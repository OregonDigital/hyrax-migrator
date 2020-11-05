# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare the checksums from the source asset and the migrated asset
  class VerifyChecksumsService
    def initialize(migrator_work, hyrax_asset, original_profile)
      @migrator_work = migrator_work
      @hyrax_asset = hyrax_asset
      @original_profile = original_profile
      @new_profile = new_profile
      @errors = verify_content
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

    def verify_content
      return [] if @original_profile['checksums'].blank?

      errors = []
      @original_profile['checksums'].each do |key, val|
        next if val.blank?

        errors << "Content does not match precomputed #{key} checksums for #{@migrator_work.pid}. Source: #{val.first} Migrated: #{@new_profile[:checksums][key]}" unless val.first == @new_profile[:checksums][key]
      end
      errors
    end
  end
end
