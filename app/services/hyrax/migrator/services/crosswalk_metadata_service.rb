# frozen_string_literal:true

require 'rdf'
require 'rdf/ntriples'

module Hyrax::Migrator::Services
  # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
  class CrosswalkMetadataService
    include RDF
    NT_FILE = 'descmetadata.nt'

    def initialize(work, migrator_config)
      @work = work
      @data_dir = File.join(work.file_path, 'data')
      @config = migrator_config
    end

    # returns result hash
    def crosswalk
      graph = create_graph
      graph.statements.each do |statement|
        data = lookup(statement.predicate.to_s)
        processed_obj = process(data, statement.object)
        assemble_hash(data, processed_obj)
      end
      @result
    end

    private

    # Load the nt file and return graph
    def create_graph
      RDF::Graph.load(nt_file)
    end

    # Find and return the ntriple file
    def nt_file
      files = Dir.entries(@data_dir)
      file = files.find { |f| f.downcase.end_with?(NT_FILE) }
      raise StandardError, "could not find ntriple file in #{@data_dir}" unless file

      File.join(@data_dir, file)
    rescue Errno::ENOENT
      raise StandardError, "data directory #{@data_dir} not found"
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

    # Given an OD2 predicate, returns associated property data or nil
    def lookup(predicate)
      hash = crosswalk_hash
      result = hash.select { |k| k[:predicate].casecmp(predicate).zero? }
      return result.first unless result.empty?

      raise PredicateNotFoundError, predicate
    end

    # Given property data and an OD1 object, returns either the object, or a modified object
    def process(data, object)
      data[:function].blank? ? object : eval(data[:function]).call(object)
    end

    # Returns a hash that maps OD2 predicates to OD2 properties and other data needed to process each field.
    def crosswalk_hash
      @crosswalk_hash ||= @crosswalk_data[:crosswalk] + @crosswalk_probs[:problems]
    end

    def crosswalk_data
      @crosswalk_data ||= YAML.load_file(@config.crosswalk_metadata_file).deep_symbolize_keys
    end

    def crosswalk_probs
      @crosswalk_probs ||= YAML.load_file(@config.problems_metadata_file).deep_symbolize_keys
    end

    # Raise in lookup
    class PredicateNotFoundError < StandardError
    end

    # Use in object modifying functions, identify object in message
    class ModifyObjectFailedError < StandardError
    end
  end
end
