# frozen_string_literal:true

require 'rdf'
require 'rdf/ntriples'
require 'uri'

module Hyrax::Migrator
  # Methods for mapping OD1 metadata to OD2
  class CrosswalkMetadata
    def initialize(crosswalk_metadata_file, crosswalk_overrides_file)
      @crosswalk_metadata_file = crosswalk_metadata_file
      @crosswalk_overrides_file = crosswalk_overrides_file
    end

    def crosswalk
      graph = create_graph
      graph.statements.each do |statement|
        data = lookup(statement.predicate.to_s)
        next if data.nil?

        processed_obj = process(data, statement.object)
        next if processed_obj.nil?

        assemble_hash(data, processed_obj)
      end
      @result
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

    def create_graph; end

    def find(predicate)
      proc { |k| k[:predicate].casecmp(predicate).zero? }
    end

    # Given an OD2 predicate, returns associated property data or nil
    def lookup(predicate)
      hash = crosswalk_hash
      result = hash.select(&find(predicate))
      return result.first unless result.empty?
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
      @crosswalk_data ||= YAML.load_file(@crosswalk_metadata_file).deep_symbolize_keys
      @crosswalk_data[:crosswalk]
    end

    def crosswalk_overrides
      @crosswalk_overrides ||= YAML.load_file(@crosswalk_overrides_file).deep_symbolize_keys
      @crosswalk_overrides[:overrides]
    end

    def return_nil(_object)
      nil
    end

    ##
    # Generate the data necessary for a Rails nested attribute
    def attributes_data(object)
      return { 'id' => object.to_s, '_destroy' => 0 } unless valid_uri(object.to_s).nil?
    end

    def valid_uri(uri)
      uri =~ URI.regexp(%w[http https])
    end

    # Raise in lookup
    class PredicateNotFoundError < StandardError
    end

    # Use in object modifying functions, identify object in message
    class ModifyObjectFailedError < StandardError
    end
  end
end
