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

    context 'when a predicate is in both files' do
      let(:overrides) { [{ property: 'rights-statement', predicate: 'http://purl.org/dc/terms/rights', multiple: false }] }

      before do
        allow(service).to receive(:crosswalk_overrides).and_return(overrides)
      end

      it 'favors overrides' do
        p = service.send(:find, 'http://purl.org/dc/terms/rights')
        result = service.send(:crosswalk_hash)
        expect(result.select(&p).size).to eq(1)
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

    context 'when given a predicate that is not in the config and skip_field_mode is true' do
      let(:bad_predicate) { 'http://example.org/ns/iDontExist' }

      before { config.skip_field_mode = true }

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn)
        service.send(:lookup, bad_predicate)
      end
      it 'returns nil' do
        expect(service.send(:lookup, bad_predicate)).to eq(nil)
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

    context 'when there is an nt with set and primary_set to process' do
      let(:set_statement) do
        RDF::Statement.new(
          RDF::URI('http://oregondigital.org/resource/oregondigital:abcde1234'),
          RDF::URI('http://opaquenamespace.org/ns/set'),
          RDF::URI('http://oregondigital.org/resource/oregondigital:osu-scarc')
        )
      end

      let(:primary_set_statement) do
        RDF::Statement.new(
          RDF::URI('http://oregondigital.org/resource/oregondigital:abcde1234'),
          RDF::URI('http://opaquenamespace.org/ns/primarySet'),
          RDF::URI('http://oregondigital.org/resource/oregondigital:osu-baseball')
        )
      end

      let(:creator_statement) { RDF::Statement.new(RDF::URI(rdfsubject), RDF::URI(predicate), RDF::URI(object)) }

      let(:graph) do
        g = RDF::Graph.new
        g << set_statement
        g << primary_set_statement
        g << creator_statement
        g
      end

      it 'excludes :set from result hash' do
        expect(service.crosswalk[:set]).to be_nil
      end

      it 'excludes :primary_set from result hash' do
        expect(service.crosswalk[:primary_set]).to be_nil
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

  context 'with attributes_data function' do
    let(:predicate_str) { 'http://purl.org/dc/terms/format' }
    let(:predicate) { RDF::URI(predicate_str) }
    let(:object) { RDF::URI('http://test/test') }
    let(:data) { { property: 'format_attributes', predicate: predicate_str, multiple: true, function: 'attributes_data' } }

    it 'transforms the object using the function' do
      expect(service.crosswalk[:format_attributes]).to eq [{ '_destroy' => 0, 'id' => 'http://test/test' }]
    end
  end
end
