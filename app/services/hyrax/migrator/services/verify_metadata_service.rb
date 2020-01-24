# frozen_string_literal:true
require 'yaml'
module Hyrax::Migrator::Services
  ##
  # A service to compare metadata from the source asset and the migrated asset
  class VerifyMetadataService
    def initialize(migrator_work, migrator_config)
      @work = migrator_work
      @data_dir = File.join(work.working_directory, 'data') 
      @config = migrator_config
      @new_profile = get_profile
    end

    def item
      @item ||= Hyrax::Migrator::HyraxCore::Asset.find(@work.pid)
    end
    
    # pull metadata for asset in OD2
    def get_profile
      result_hash = {}
      result_hash[:colls] = colls
      result_hash[:fields] = fields
      result_hash[:admin_set] = item.admin_set_id
      result_hash
    end

    def fields
      fields = {}
      item.as_json.each do |field, val|
        next if val.blank?
        
        if val.respond_to? :to_a
          fields[field] = []
          val.each do |v|
            fields[field] << extract(v)
          end
        else
          fields[field] = extract val
        end
      end
      fields
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
      original_profile['fields'].each do |k, val|
        next if val.blank?
        
        new_field = map_fields['fields'][k]
        if @new_profile[:fields][new_field].blank?
          errors << "Unable to verify #{k} in #{pid}."
        else
          val.each do |v|
            test = original_profile['fields'][k].kind_of?(Array) ? @new_profile[:fields][new_field].include?(v.to_s) : @new_profile[:fields][new_field] == v.to_s
            errors << "Unable to verify #{k} in #{pid}." unless test
          end
        end
      end
      errors
    rescue StandardError => e
      puts e.message
    end

    def extract(val)
      str = val.respond_to?(:rdf_subject) ? val.rdf_subject.to_s : val
      str
    end

    def original_profile
      @profile ||= YAML.load_file(File.join(@data_dir, "#{@work.pid}_profile.yml"))
    end

    def map_fields
      @map ||= YAML.load_file(@config.fields_map)
    end

  end
end

