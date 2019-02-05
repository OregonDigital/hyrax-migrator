# frozen_string_literal: true

require 'rdf'

RSpec.describe Hyrax::Migrator::Services::CrosswalkMetadataService do
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
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:pid) { '3t945r08v' }
  let(:crosswalk_metadata_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk.yml') }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:service) { described_class.new(work, config) }
  let(:result_hash) { { creator: object } }

  before do
    config.crosswalk_metadata_file = crosswalk_metadata_file
    allow(RDF::Graph).to receive(:load).and_return(graph)
  end

  describe 'lookup' do
    context 'when given a predicate' do
      it 'returns the associated property hash' do
        expect(service.send(:lookup, predicate_str)).to eq data
      end
    end

    context 'when given a predicate that is not in the config' do
      let(:bad_predicate) { 'http://example.org/ns/iDontExist' }
      let(:error) { Hyrax::Migrator::Services::CrosswalkMetadataService::PredicateNotFoundError }

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
    context 'when there is an nt to process' do
      it 'processes the statements and returns a result hash' do
        response = service.crosswalk
        expect(response[:creator]).to eq([object])
      end
    end
  end
end
