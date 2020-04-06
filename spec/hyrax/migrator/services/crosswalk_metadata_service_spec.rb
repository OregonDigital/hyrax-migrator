# frozen_string_literal: true

require 'rdf'
require 'uri'
require 'hyrax/migrator/crosswalk_metadata'

RSpec.describe Hyrax::Migrator::Services::CrosswalkMetadataService do
  let(:graph) do
    g = RDF::Graph.new
    s = RDF::Statement.new(rdfsubject, predicate, rdfobject)
    g << s
    g
  end
  let(:rdfsubject) { RDF::URI('http://oregondigital.org/resource/oregondigital:abcde1234') }

  let(:predicate_str) { 'http://purl.org/dc/terms/format' }
  let(:predicate) { RDF::URI(predicate_str) }
  let(:rdfobject) { RDF::URI('http://formats_r_us.org/thing') }
  let(:data) { { property: 'format_attributes', predicate: predicate_str, multiple: true, function: 'attributes_data' } }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:crosswalk_metadata_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk.yml') }
  let(:crosswalk_overrides_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk_overrides.yml') }
  let(:service) { described_class.new(work, config) }
  let(:pid) { '3t945r08v' }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }

  before do
    config.crosswalk_metadata_file = crosswalk_metadata_file
    config.crosswalk_overrides_file = crosswalk_overrides_file
    allow(RDF::Graph).to receive(:load).and_return(graph)
  end

  describe 'lookup' do
    let(:predicate) { RDF::URI('http://badpredicates.org/ns/bad') }
    let(:error) { Hyrax::Migrator::Services::CrosswalkMetadataService::PredicateNotFoundError }

    context 'when the result is nil' do
      it 'raises an error' do
        expect { service.send(:lookup, predicate.to_s) }.to raise_error(error)
      end

      context 'when skip_field_mode is enabled' do
        before do
          config.skip_field_mode = true
          service.send(:lookup, predicate.to_s)
        end

        it 'reports the error' do
          expect(service.instance_variable_get(:@errors).size).to eq 1
        end
      end
    end
  end

  describe 'crosswalk' do
    context 'when there is valid metadata' do
      it 'returns results' do
        expect(service.crosswalk[:format_attributes]).to eq [{ '_destroy' => 0, 'id' => 'http://formats_r_us.org/thing' }]
      end
    end

    context 'when there are errors' do
      let(:predicate) { RDF::URI('http://badpredicates.org/ns/bad') }

      it 'reports them' do
        service.crosswalk
      rescue Hyrax::Migrator::Services::CrosswalkMetadataService::PredicateNotFoundError
        result = service.instance_variable_get(:@result)
        expect(result[:errors].size).to eq 1
      end
    end
  end

  describe 'attributes_data' do
    let(:rdfobject) { RDF::Literal('blah blah') }
    let(:error) { URI::InvalidURIError }

    it 'raises an error' do
      expect { service.send(:attributes_data, rdfobject) }.to raise_error(error)
    end

    context 'when skip field mode is enabled' do
      before do
        config.skip_field_mode = true
      end

      it 'adds errors to the result' do
        service.send(:attributes_data, rdfobject)
        expect(service.instance_variable_get(:@errors).size).to eq 1
      end
      it 'returns nil' do
        expect(service.send(:attributes_data, rdfobject)).to eq nil
      end
    end
  end
end
