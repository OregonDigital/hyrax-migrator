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
  let(:data) { { property: 'creator', predicate: predicate_str, multiple: true } }
  let(:service) { described_class.new }
  let(:result_hash) { { creator: object } }

  describe 'lookup' do
    context 'when given a predicate' do
      it 'returns the associated property hash' do
        expect(service.send(:lookup, predicate_str)).to eq data
      end
    end

    context 'when given a predicate that is not in the config' do
      let(:bad_predicate) { 'http://example.org/ns/iDontExist' }
      let(:error) { Hyrax::Migrator::CrosswalkMetadataService::PredicateNotFoundError }

      it 'raises an error' do
        expect { service.send(:lookup, bad_predicate) }.to raise_error(error)
      end
    end
  end

  describe 'process' do
    context 'when given a property hash that does not contain a function' do
      it 'returns the object' do
        expect(service.send(:process, data, object)).to eq(object)
      end
    end

    context 'when given a property hash that does have a function' do
      let(:predicate2_str) { 'http://example.org/ns/myFakePred' }
      let(:object2) { RDF::Literal('my little pony') }
      let(:data2) { { property: 'test', predicate: predicate2_str, function: 'add_foo', multiple: true } }

      before do
        described_class.class_eval do
          def add_foo(obj)
            RDF::Literal(obj.to_s + ' foo')
          end
        end
        allow(service).to receive(:lookup).and_return(data2)
      end

      it 'modifies the object' do
        expect(service.send(:process, data2, object2)).to eq(RDF::Literal('my little pony foo'))
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
