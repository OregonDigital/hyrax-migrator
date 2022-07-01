# frozen_string_literal:true

module Hyrax::Migrator::Services
  # rubocop:disable Metrics/ClassLength
  # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
  class CrosswalkMetadataService < Hyrax::Migrator::CrosswalkMetadata
    def initialize(work, migrator_config)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
      @config = migrator_config
      set_configs
      @result = {}
      @errors = []
      @info = []
    end

    def set_configs
      @skip_field_mode = @config.skip_field_mode
      @crosswalk_metadata_file = @config.crosswalk_metadata_file
      @crosswalk_overrides_file = @config.crosswalk_overrides_file
      @crosswalk_admin_sets_file = @config.crosswalk_admin_sets_file
    end

    # returns result hash
    def crosswalk
      super
    ensure
      @result[:errors] = @errors unless @errors.empty?
      @result[:info] = @info unless @info.empty?
      @result
    end

    def update
      @new_attrs = crosswalk
      promote_blanks_cvs
      promote_blanks_strings
      promote_destroys
      @new_attrs
    end

    private

    # Load the nt file and return graph
    def graph
      Hyrax::Migrator::Services::CreateGraphService.call(@data_dir)
    end

    # Given an OD2 predicate, returns associated property data or nil
    def lookup(predicate)
      result = super
      return result unless result.nil?

      @errors << "Predicate not found: #{predicate} during crosswalk for #{@work.pid}"
      return nil if @skip_field_mode

      raise PredicateNotFoundError, predicate
    end

    ##
    # Generate the data necessary for a Rails nested attribute
    def attributes_data(object)
      result = super
      return result unless result.nil?

      @errors << "Invalid URI #{object} found in crosswalk of #{@work.pid}"
      return nil if @skip_field_mode

      raise URI::InvalidURIError, object.to_s
    end

    def log_info(object)
      @info << object.to_s
      nil
    end

    # for use with set on the crosswalk
    def full_size_hack(object)
      return nil if @result[:full_size_download_allowed] == 0

      id = object.to_s.split(':')[2]
      record = admin_set_map.select { |coll| coll[:primary_set] == id }.first
      data = lookup('http://opaquenamespace.org/ns/fullSizeDownloadAllowed')
      assemble_hash(data, record[:full_size_download]) unless record.blank?
      nil
    end

    def admin_set_map
      yaml = YAML.load_file(@crosswalk_admin_sets_file).deep_symbolize_keys
      yaml[:primary_set_crosswalk]
    end

    def mark_destroy(cv_val)
      cv_val['_destroy'] = 1
      cv_val
    end

    def crosswalk_ignore
      %i[visibility admin_set_id member_of_collections_attributes work_members_attributes]
    end

    def old_attrs
      @work.env[:attributes].clone.reject { |k, _v| crosswalk_ignore.include? k }
    end

    def blanks
      old_attrs.select { |key, _val| @new_attrs[key].nil? }
    end

    def cv_attrs
      old_attrs.select { |key, _val| key.to_s.include? 'attributes' }
    end

    def promote_blanks_cvs
      blanks.select { |key, _val| key.to_s.include? 'attributes' }.each do |key, val|
        if !val.is_a? Array
          @new_attrs[key] = mark_destroy(val)
        else
          @new_attrs[key] ||= []
          val.each do |v|
            @new_attrs[key] << mark_destroy(v)
          end
        end
      end
    end

    def promote_blanks_strings
      blanks.reject { |key, _val| key.to_s.include? 'attributes' }.each do |key, val|
        @new_attrs[key] = (val.is_a? Array) ? [] : ''
      end
    end

    def promote_destroys
      cv_attrs.select { |_key, val| val.is_a? Array }.each do |key, _val|
        @new_attrs[key] ||= []
        (old_attrs[key] - @new_attrs[key]).each do |cv_val|
          @new_attrs[key] << mark_destroy(cv_val)
        end
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
