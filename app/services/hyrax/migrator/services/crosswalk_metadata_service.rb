# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
  class CrosswalkMetadataService < Hyrax::Migrator::CrosswalkMetadata
    def initialize(work, migrator_config)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
      @config = migrator_config
      @skip_field_mode = migrator_config.skip_field_mode
      @crosswalk_metadata_file = @config.crosswalk_metadata_file
      @crosswalk_overrides_file = @config.crosswalk_overrides_file
      @result = {}
      @errors = []
    end

    # returns result hash
    def crosswalk
      super
    ensure
      @result[:errors] = @errors unless @errors.empty?
      @result
    end

    private

    # Load the nt file and return graph
    def create_graph
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
  end
end
