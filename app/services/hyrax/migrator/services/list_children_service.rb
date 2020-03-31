# frozen_string_literal:true

require 'rdf'
require 'rdf/ntriples'

module Hyrax::Migrator::Services
  # Called by the ListChildrenActor
  class ListChildrenService
    CONTENTS_PREDICATE = 'http://opaquenamespace.org/ns/contents'
    def initialize(work, migrator_config)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
      @config = migrator_config
    end

    def list_children
      children = {}
      return children if contents.blank?

      contents.each_with_index do |item, index|
        child_id = item.gsub('http://oregondigital.org/resource/oregondigital:', '')
        children[index.to_s] = { 'id' => child_id }
      end
      children
    end

    # Using reader instead of graph to preserve order
    def contents
      results = []
      RDF::Reader.open(nt_path) do |reader|
        reader.each_statement do |s|
          results << s.object.to_s if s.predicate.to_s.casecmp(CONTENTS_PREDICATE).zero?
        end
      end
      results
    end

    def nt_path
      "#{@data_dir}/#{@work.pid}_descMetadata.nt"
    end
  end
end
