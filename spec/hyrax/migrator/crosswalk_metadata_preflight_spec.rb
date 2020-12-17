# frozen_string_literal: true

require 'rdf'
require 'uri'
require 'hyrax/migrator/crosswalk_metadata_preflight'

RSpec.describe Hyrax::Migrator::CrosswalkMetadataPreflight do
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
  let(:descMetadata) { double }
  let(:work) { double }
  let(:service) { described_class.new(crosswalk_metadata_file, crosswalk_overrides_file) }

  before do
    service.work = work
    service.errors = []
    service.result = {}
    allow(work).to receive(:descMetadata).and_return(descMetadata)
    allow(descMetadata).to receive(:graph).and_return(graph)
  end

  describe 'lookup' do
    let(:predicate) { RDF::URI('http://badpredicates.org/ns/bad') }

    before do
      service.send(:lookup, predicate)
    end

    context 'when the result is nil' do
      it 'reports the error' do
        expect(service.instance_variable_get(:@errors).size).to eq 1
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
        expect(service.crosswalk[:errors].size).to eq 1
      end
    end
  end

  describe 'attributes_data' do
    let(:rdfobject) { RDF::Literal('blah blah') }

    context 'when there is a string' do
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
