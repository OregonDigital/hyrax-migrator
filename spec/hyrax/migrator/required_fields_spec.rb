# frozen_string_literal: true

require 'rdf'
require 'hyrax/migrator/required_fields'

RSpec.describe Hyrax::Migrator::RequiredFields do
  let(:service) { described_class.new(required_fields_file) }
  let(:required_fields_file) { File.join(Rails.root, '..', 'fixtures', 'required_fields.yml') }
  let(:attributes) do
    hash = {}
    hash[:title] = ['Conjunction Junction']
    hash[:identifier] = ['123456']
    hash[:type_attributes] = [RDF::URI('http://purl.org/dc/dcmitype/Audio')]
    hash[:rights_statement] = [RDF::URI('http://rightsstatments.org/vocab/InC/1.0/')]
    hash
  end

  before do
    service.attributes = attributes
  end

  context 'when the fields are all present' do
    it 'returns an empty array' do
      expect(service.verify_fields).to eq []
    end
  end

  context 'when there is a field missing' do
    before do
      attributes.delete :title
      service.attributes = attributes
    end

    it 'returns the missing field' do
      expect(service.verify_fields).to eq ['missing required field: title']
    end
  end
end
