# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare metadata from the source asset and the migrated asset
  class VerifyMetadataService
    def initialize(migrator_work, migrator_config, profile_dir = nil)
      @work = migrator_work
      @profile_dir = profile_dir.nil? ? File.join(@work.working_directory, 'data') : profile_dir
      @config = migrator_config
      @new_profile = new_profile
    end

    def item
      @item ||= Hyrax::Migrator::HyraxCore::Asset.find(@work.pid)
    end

    def content
      fs = item.file_sets.first
      fs.original_file.content unless fs.blank?
    end

    # pull metadata for asset in OD2
    def new_profile
      result_hash = {}
      result_hash[:colls] = colls
      result_hash[:fields] = fields
      result_hash[:checksums] = checksums
      result_hash[:admin_set] = item.admin_set_id
      result_hash
    end

    def fields
      fields = {}
      item.as_json.each do |field, val|
        next if val.blank?

        fields[field] = val.respond_to?(:to_a) ? field_array(val) : extract(val)
      end
      fields
    end

    def checksums
      checksums = {}
      checksums['SHA1hex'] = Digest::SHA1.hexdigest content
      checksums['SHA1base64'] = Digest::SHA1.base64digest content
      checksums['MD5hex'] = Digest::MD5.hexdigest content
      checksums['MD5base64'] = Digest::MD5.base64digest content
      checksums
    end

    def field_array(val)
      arr = []
      val.each do |v|
        arr << extract(v)
      end
      arr
    end

    def colls
      colls = []
      item.member_of_collections.each do |coll|
        colls << coll.id
      end
      colls
    end

    def verify_metadata
      errors = []
      original_profile['fields'].each do |key, val|
        next if val.blank?

        errors += process_vals(key, val)
      end
      errors
    rescue StandardError => e
      puts e.message
    end

    def verify_content
      errors = []

      original_profile['checksums'].each do |key, val|
        next if val.blank?

        errors << "Content does not match precomputed #{key} checksums for #{@work.pid}. Source: #{val.first} Migrated: #{@new_profile[:checksums][key]}" unless val.first == @new_profile[:checksums][key]
      end
      errors
    rescue StandardError => e
      puts e.message
    end

    def process_vals(key, val)
      errors = []
      val.each do |v|
        errors << "Unable to verify #{key} in #{@work.pid}." unless test_val(key, v)
      end
      errors
    end

    def test_val(key, val)
      new_field = map_fields['fields'][key]
      return @new_profile[:fields][new_field].include?(val.to_s) if original_profile['fields'][key].is_a?(Array)

      @new_profile[:fields][new_field] == val.to_s
    rescue StandardError
      false
    end

    def extract(val)
      str = val.respond_to?(:rdf_subject) ? val.rdf_subject.to_s : val
      str
    end

    def original_profile
      @original_profile ||= YAML.load_file(File.join(@profile_dir, "#{@work.pid}_profile.yml"))
    end

    def map_fields
      @map_fields ||= YAML.load_file(@config.fields_map)
    end
  end
end
