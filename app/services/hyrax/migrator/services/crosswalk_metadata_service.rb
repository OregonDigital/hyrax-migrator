# frozen_string_literal:true

require 'rdf'
require 'rdf/ntriples'

module Hyrax::Migrator::Services
  # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
  class CrosswalkMetadataService
    PRIMARY_SET_PREDICATE = 'http://opaquenamespace.org/ns/primarySet'
    SET_PREDICATE = 'http://opaquenamespace.org/ns/set'

    def initialize(work, migrator_config)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
      @config = migrator_config
    end

    # returns result hash
    def crosswalk
      graph = create_graph
      graph.statements.each do |statement|
        next if excluded_predicates.include? statement.predicate.to_s

        data = lookup(statement.predicate.to_s)
        processed_obj = process(data, statement.object)
        assemble_hash(data, processed_obj)
      end
      @result
    end

    private

    def excluded_predicates
      [PRIMARY_SET_PREDICATE, SET_PREDICATE]
    end

    # Load the nt file and return graph
    def create_graph
      Hyrax::Migrator::Services::CreateGraphService.call(@data_dir)
    end

    # Given property data and an object, adds them to result hash
    def assemble_hash(data, object)
      return if data[:property].blank?

      @result ||= {}
      if data[:multiple]
        @result[data[:property].to_sym] ||= []
        @result[data[:property].to_sym] += [object]
      else
        @result[data[:property].to_sym] = object
      end
    end

    def find(predicate)
      proc { |k| k[:predicate].casecmp(predicate).zero? }
    end

    # Given an OD2 predicate, returns associated property data or nil
    def lookup(predicate)
      hash = crosswalk_hash
      result = hash.select(&find(predicate))
      return result.first unless result.empty?

      raise PredicateNotFoundError, predicate
    end

    # Given property data and an OD1 object, returns either the object, or a modified object
    def process(data, object)
      data[:function].blank? ? object.to_s : send(data[:function].to_sym, object.to_s)
    end

    # Returns a hash that maps OD2 predicates to OD2 properties and other data needed to process each field.
    def crosswalk_hash
      unique = crosswalk_data.reject { |x| crosswalk_overrides.one?(&find(x[:predicate])) }
      @crosswalk_hash ||= crosswalk_overrides + unique
    end

    def crosswalk_data
      @crosswalk_data ||= YAML.load_file(@config.crosswalk_metadata_file).deep_symbolize_keys
      @crosswalk_data[:crosswalk]
    end

    def crosswalk_overrides
      @crosswalk_overrides ||= YAML.load_file(@config.crosswalk_overrides_file).deep_symbolize_keys
      @crosswalk_overrides[:overrides]
    end

    def return_nil(_object)
      nil
    end

    ##
    # Generate the data necessary for a Rails nested attribute
    def attributes_data(object)
      { 'id' => object.to_s, '_destroy' => 0 }
    end

    # Raise in lookup
    class PredicateNotFoundError < StandardError
    end

    # Use in object modifying functions, identify object in message
    class ModifyObjectFailedError < StandardError
    end
  end
end
