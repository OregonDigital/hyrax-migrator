# frozen_string_literal:true

require 'rdf'

module Hyrax::Migrator::Services
  ##
  # A service to inspect the metadata and crosswalk the type to a model used for migration
  class ModelLookupService
    include RDF

    TYPE_URI = 'http://purl.org/dc/terms/type'
    METADATA_FILE = 'descmetadata.nt'
    METADATA_FORMAT = :ntriples

    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
      crosswalk
    end

    ##
    # Using the configured crosswalk for model lookup,
    def model
      object = object(graph)
      lookup_model(object)
    end

    private

    def crosswalk
      @crosswalk ||= YAML.load_file(@config.model_crosswalk)
    rescue Errno::ENOENT
      raise StandardError, "could not find model lookup configuration at #{@config.model_crosswalk}"
    end

    def metadata_file
      files = @work.bag.bag_files
      file = files.find { |f| f.downcase.end_with?(METADATA_FILE) }
      raise StandardError, "could not find a metadata file ending with '#{METADATA_FILE}' in #{@work.bag.data_dir}" unless file

      file
    end

    def graph
      RDF::Graph.load(metadata_file, format: METADATA_FORMAT)
    rescue RDF::FormatError
      raise StandardError, "invalid metadata format, could not load #{METADATA_FORMAT} metadata file"
    rescue IOError
      raise StandardError, "could not find metadata file at #{metadata_file}"
    end

    def lookup_model(object)
      model = crosswalk[object.to_s]
      raise StandardError, "could not find a configuration for #{object} in #{@config.model_crosswalk}" unless model

      message = "#{model} not a registered model in the migrator initializer"
      raise StandardError, message unless @config.models.include?(model)

      model
    end

    def object(graph)
      statement = graph.statements.find { |s| predicate?(s) }
      raise StandardError, "could not find #{TYPE_URI} in metadata" if statement.nil?

      statement.object
    end

    def predicate?(statement)
      statement.predicate.to_s.casecmp(TYPE_URI).zero?
    end
  end
end
