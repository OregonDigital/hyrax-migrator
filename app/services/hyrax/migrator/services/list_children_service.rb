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
      @graph = create_graph
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

    def contents
      @graph.statements.select { |s| s.predicate.to_s.casecmp(CONTENTS_PREDICATE).zero? }.map { |r| r.object.to_s }
    end

    def create_graph
      Hyrax::Migrator::Services::CreateGraphService.call(@data_dir)
    end
  end
end
