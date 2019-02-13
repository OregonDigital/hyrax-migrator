# frozen_string_literal: true

require 'rdf'

RSpec.describe Hyrax::Migrator::Services::CrosswalkMetadataService do
  let(:graph) do
    g = RDF::Graph.new
    s = RDF::Statement.new(RDF::URI(rdfsubject), RDF::URI(predicate), RDF::URI(object))
    g << s
    g
  end
  let(:rdfsubject) { RDF::URI('http://oregondigital.org/resource/oregondigital:abcde1234') }
  let(:predicate_str) { 'http://purl.org/dc/elements/1.1/creator' }
  let(:predicate) { RDF::URI(predicate_str) }
  let(:object) { RDF::URI('http://id.loc.gov/authorities/names/nr93013379') }
  let(:data) { { property: 'creator', predicate: predicate_str, multiple: true } }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:pid) { '3t945r08v' }
  let(:crosswalk_metadata_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk.yml') }
  let(:crosswalk_overrides_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk_overrides.yml') }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:service) { described_class.new(work, config) }
  let(:result_hash) { { creator: [object.to_s] } }
  let(:predicate2_str) { 'http://opaquenamespace.org/ns/fullText' }
  let(:object2) { RDF::Literal('my little pony') }
  let(:data2) { { predicate: predicate2_str, function: 'return_nil' } }
  let(:predicate2) { RDF::URI(predicate2_str) }
  let(:data3) { { property: 'resource_type', predicate: 'http://my_little_pred', multiple: false } }

  before do
    config.crosswalk_metadata_file = crosswalk_metadata_file
    config.crosswalk_overrides_file = crosswalk_overrides_file
    allow(RDF::Graph).to receive(:load).and_return(graph)
  end

  describe 'nt_file' do
    context 'when there is a file with a valid path' do
      it 'finds the file' do
        expect(service.send(:nt_file)).to eq("#{file_path}/data/#{pid}_descMetadata.nt")
      end
    end

    context 'when it cant find the file' do
      let(:error) { StandardError }

      before do
        work.file_path = '/some_path'
      end

      it 'raises an error' do
        expect { service.send(:nt_file) }.to raise_error(error)
      end
    end
  end

  describe 'assemble_hash' do
    context 'when given a property and an object' do
      it 'adds the property and object to the result' do
        service.send(:assemble_hash, data, object.to_s)
        expect(service.instance_variable_get(:@result)).to eq(result_hash)
      end
    end

    context 'when given a property that takes only single values' do
      it 'does not put the object in an array' do
        service.send(:assemble_hash, data3, object2.to_s)
        expect(service.instance_variable_get(:@result)[:resource_type]).not_to be(Array)
      end
    end
  end

  describe 'crosswalk_hash' do
    context 'when the lookup files exist' do
      it 'loads the OD2 properties into an array of hashes' do
        expect(service.send(:crosswalk_hash)).to include(data)
      end
      it 'loads the override predicates into the array of hashes' do
        expect(service.send(:crosswalk_hash)).to include(data2)
      end
    end
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
        expect(service.send(:process, data, object)).to eq(object.to_s)
      end
    end

    context 'when given a property hash that does have a function' do
      it 'modifies the object' do
        expect(service.send(:process, data2, object2)).to eq(nil)
      end
    end
  end

  describe 'crosswalk' do
    context 'when there is an nt to process' do
      it 'processes the statements and returns a result hash' do
        response = service.crosswalk
        expect(response[:creator]).to eq([object.to_s])
      end
    end

    context 'when processing uses the nil function' do
      before do
        graph << RDF::Statement(rdfsubject, predicate2, object2)
      end

      it 'keeps calm and carries on' do
        response = service.crosswalk
        expect(response.keys).to eq([:creator])
      end
    end
  end
end
