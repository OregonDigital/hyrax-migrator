# frozen_string_literal:true

require 'rdf'

module Hyrax
  module Migrator
    # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
    class CrosswalkMetadataService
      include RDF

      def initialize(config = 'config/migrator/crosswalk.yml')
        @config = config
      end

      # Given a graph, returns result hash
      def crosswalk(graph)
        graph.statements.each do |statement|
          data = lookup(statement.predicate.to_s)
          processed_obj = process(data, statement.object)
          assemble_hash(data, processed_obj)
        end
        @result
      end

      private

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

      # Given an OD2 predicate, returns associated property data or nil
      def lookup(predicate)
        hash = crosswalk_hash[:crosswalk]
        result = hash.select { |k| k[:predicate].casecmp(predicate).zero? }
        return result.first unless result.empty?

        raise PredicateNotFoundError, predicate
      end

      # Given property data and an OD1 object, returns either the object, or a modified object
      def process(data, object)
        data[:function].blank? ? object : send(data[:function].to_sym, object)
      end

      # Returns a hash that maps OD2 predicates to OD2 properties and other data needed to process each field.
      def crosswalk_hash
        @crosswalk_hash ||= YAML.load_file(@config).deep_symbolize_keys
      end

      # Raise in lookup
      class PredicateNotFoundError < StandardError
      end

      # Use in object modifying functions, identify object in message
      class ModifyObjectFailedError < StandardError
      end
    end
  end
end
