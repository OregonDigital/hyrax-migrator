# frozen_string_literal: true

require 'rdf'
require 'rdf/ntriples'

module Hyrax::Migrator::Services
  # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
  class CreateGraphService
    include RDF
    NT_FILE = 'descmetadata.nt'

    def self.call(data_dir)
      new(data_dir).call
    end

    # Load the nt file and return graph
    def call
      RDF::Graph.load(nt_file)
    end

    private

    def initialize(data_dir)
      @data_dir = data_dir
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
  end
end
