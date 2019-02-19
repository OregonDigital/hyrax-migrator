# frozen_string_literal:true

require 'rdf'
require 'rdf/ntriples'

module Hyrax::Migrator::Services
  # Called by the ListChildrenActor
  class ListChildrenService
    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
    end

    def list_children
      return nil if @work.env[:attributes][:contents].blank?

      children = {}
      @work.env[:attributes][:contents].each_with_index do |item, index|
        child_id = item.gsub('http://oregondigital.org/resource/oregondigital:', '')
        children[index.to_s] = { 'id' => child_id }
      end
      children
    end
  end
end
