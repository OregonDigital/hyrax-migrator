# frozen_string_literal: true

require 'rdf'
require 'byebug'

RSpec.describe Hyrax::Migrator::Services::CreateGraphService do
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
  let(:pid) { '3t945r08v' }
  let(:data_dir) { File.join(Rails.root, '..', 'fixtures', pid, 'data') }
  let(:service) { described_class }

  before do
    allow(RDF::Graph).to receive(:load).and_return(graph)
  end

  describe '#call' do
    context 'when there is a file with a valid path' do
      it 'finds the file' do
        expect(service.call(data_dir)).to eq graph
      end
    end

    context 'when it cant find the file' do
      let(:error) { StandardError }
      let(:data_dir) { 'unknown-path' }

      it 'raises an error' do
        expect { service.call(data_dir) }.to raise_error(error)
      end
    end
  end
end
