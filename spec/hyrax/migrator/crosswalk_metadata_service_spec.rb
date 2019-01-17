# frozen_string_literal: true

require 'rdf'

RSpec.describe Hyrax::Migrator::CrosswalkMetadataService do
  let(:graph) do
    g = RDF::Graph.new
    s = RDF::Statement.new(RDF::URI(subject), RDF::URI(predicate), RDF::URI(object))
    g << s
    g
  end
  let(:subject) { RDF::URI('http://oregondigital.org/resource/oregondigital:abcde1234') }
  let(:predicate_str) { 'http://purl.org/dc/elements/1.1/creator' }
  let(:predicate) { RDF::URI(predicate_str) }
  let(:object) { RDF::URI('http://id.loc.gov/authorities/names/nr93013379') }
  let(:data) { { od2_property: 'creator', od2_predicate: predicate_str, multiple: true } }
  let(:service) { described_class.new }
  let(:result_hash) { { creator: object } }

  describe 'lookup' do
    context 'when given a predicate' do
      it 'returns the associated property hash' do
        expect(service.lookup(predicate_str)).to eq data
      end
    end
  end

  describe 'process' do
    context 'when given a property hash that does not contain a function' do
      it 'returns the object' do
        expect(service.process(data, object)).to eq(object)
      end
    end

    context 'when given a property hash that does have a function' do
      let(:predicate2_str) { 'http://example.org/ns/myFakePred' }
      let(:object2) { RDF::Literal('my little pony') }
      let(:data2) { { od2_property: 'test', od2_predicate: predicate2_str, function: 'add_foo', multiple: true } }

      it 'returns the object' do
        expect(service.process(data2, object2)).to eq(RDF::Literal('my little pony foo'))
      end
    end
  end

  describe 'crosswalk' do
    context 'when given a graph' do
      it 'processes the statements and returns a result hash' do
        response = service.crosswalk(graph)
        expect(response[:creator]).to eq([object])
      end
    end
  end
end
