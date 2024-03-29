# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare metadata from the source asset and the migrated asset
  class VerifyMetadataService < VerifyService
    def new_profile
      result_hash = {}
      result_hash[:colls] = colls
      result_hash[:fields] = fields
      result_hash[:admin_set] = @migrated_work.asset.admin_set_id
      result_hash
    end

    def map_fields
      @map_fields ||= YAML.load_file(@migrated_work.config.fields_map)
    end

    def verify
      @new_profile = new_profile
      errors = []
      @migrated_work.original_profile['fields'].each do |key, val|
        next if val.blank?

        errors += process_vals(key, val)
      end
      errors.concat check_colls
      errors
    end

    def check_colls
      errors = []
      @migrated_work.original_profile['sets']['set'].each do |s|
        errors << "missing coll: #{s}" unless @new_profile[:colls].include? s
      end
      errors
    end

    def process_vals(key, val)
      return ["Unable to verify #{key} in #{@migrated_work.work.pid}."] unless test_val(key, val)

      []
    end

    def test_val(key, val)
      new_field = map_fields['fields'][key]
      return true if new_field.nil?

      return @new_profile[:fields][new_field].to_set == val.to_set if val.is_a?(Array)

      @new_profile[:fields][new_field] == val
    rescue StandardError
      false
    end

    def extract(val)
      str = val.respond_to?(:rdf_subject) ? val.rdf_subject.to_s : val
      str
    end

    def fields
      fields = {}
      @migrated_work.asset.as_json.each do |field, val|
        next if val.blank?

        fields[field] = val.respond_to?(:to_a) ? field_array(val) : extract(val)
      end
      fields
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
      @migrated_work.asset.member_of_collections.each do |coll|
        colls << coll.id
      end
      colls
    end
  end
end
