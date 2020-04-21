# frozen_string_literal:true

require 'hyrax/migrator/required_fields'

module Hyrax::Migrator::Services
  # Service to verify that required fields are present
  class RequiredFieldsService < Hyrax::Migrator::RequiredFields
    def initialize(work, config)
      @required_fields_file = config.required_fields_file
      @attributes = work.env[:attributes]
    end
  end
end
