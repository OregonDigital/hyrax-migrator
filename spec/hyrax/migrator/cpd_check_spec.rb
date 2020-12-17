# frozen_string_literal: true

require 'rdf'
require 'hyrax/migrator/cpd_check'

RSpec.describe Hyrax::Migrator::CpdCheck do
  let(:service) { described_class.new(pidlist) }
  let(:pidlist) { 'spec/fixtures/pidlist' }
  let(:work) { double }
  let(:graph) { RDF::Graph.new }
  let(:statement) { RDF::Statement.new(subj, pred, obj) }
  let(:subj) { RDF::URI('http://oregondigital.org/resource/oregondigital:abcde1234') }
  let(:pred) { RDF::URI('http://opaquenamespace.org/ns/contents') }
  let(:obj) { RDF::URI('http://oregondigital.org/resource/oregondigital:abcde5678') }
  let(:descMetadata) { double }

  before do
    service.work = work
    graph << statement
    allow(work).to receive(:descMetadata).and_return(descMetadata)
    allow(descMetadata).to receive(:graph).and_return(graph)
  end

  describe 'check_cpd' do
    context 'when item is a cpd' do
      context 'when the children are accounted for' do
        it 'returns cpd' do
          expect(service.check_cpd).to eq('cpd')
        end
      end

      context 'when there is a child missing' do
        let(:obj) { RDF::URI('http://oregondigital.org/resource/abcde1235') }

        it 'flags the error' do
          expect(service.check_cpd).to eq 'cpd children missing'
        end
      end
    end

    context 'when item is not a cpd' do
      let(:pred) { RDF::URI('http://opaquenamespace.org/ns/fugu') }

      it 'returns empty' do
        expect(service.check_cpd).to eq ''
      end
    end
  end
end
