# frozen_string_literal:true

require 'rdf'

module Hyrax
  module Migrator
    # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
    class CrosswalkMetadataService
      include RDF

      CONFIG_FILE = 'config/migrator/crosswalk.yml'

      # Given a graph, returns result hash
      def crosswalk(graph)
        graph.statements.each do |statement|
          data = lookup(statement.predicate.to_s)
          processed_obj = process(data, statement.object)
          assemble_hash(data, processed_obj)
        end
        @result
      end

      # Given property data and an object, adds them to result hash
      def assemble_hash(data, object)
        return if data[:od2_property].blank?

        @result ||= {}
        if data[:multiple]
          @result[data[:od2_property].to_sym] ||= []
          @result[data[:od2_property].to_sym] += [object]
        else
          @result[data[:od2_property].to_sym] = object
        end
      end

      # Given an OD1 predicate, returns associated property data or nil
      def lookup(predicate)
        hash = crosswalk_hash[:crosswalk]
        (hash.select { |k| k[:od1_predicate] == predicate }).first
      rescue StandardError
        raise PredicateNotFoundError, predicate.to_s
      end

      # Given property data and an OD1 object, returns either the object, or a modified object
      def process(data, object)
        !data[:function].blank? ? send(data[:function].to_sym, object) : object
      end

      # Returns a hash that maps OD1 predicates to OD2 properties and other data needed to process each field.
      def crosswalk_hash
        @crosswalk_hash ||= YAML.load_file(CONFIG_FILE).deep_symbolize_keys
      end

      # test modifier function
      def add_foo(object)
        RDF::Literal(object.to_s + ' foo')
      rescue StandardError
        raise ModifyObjectFailedError, "Could not add foo to #{object}"
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
