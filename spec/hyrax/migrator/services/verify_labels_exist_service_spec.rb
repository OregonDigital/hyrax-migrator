# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::VerifyLabelsExistService do
  let(:migrated_work) { double }
  let(:asset) { double }
  let(:service) { described_class.new(migrated_work) }
  let(:pid) { 'df70jh899' }
  let(:properties) { [{ name: 'photographer_label', is_controlled: true, collection_facetable: true }] }
  let(:solr_doc) { { 'photographer_sim' => ['http://opaquenamespace.org/ns/creators/LemkeJim'] } }

  before do
    allow(migrated_work).to receive(:asset).and_return(asset)
    allow(asset).to receive(:id).and_return(pid)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:properties).and_return(properties)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:solr_record).with(pid).and_return(solr_doc)
  end

  describe 'verify' do
    context 'when labels exist' do
      before do
        properties << { name: 'illustrator_label', is_controlled: true, collection_facetable: true }
        solr_doc['photographer_label_sim'] = ['Jim Lemke']
        solr_doc['illustrator_sim'] = ['http://opaquenamespace.org/ns/creators/RabunSJ']
        solr_doc['illustrator_label_sim'] = ['SJ Rabun']
        solr_doc['creator_combined_label_sim'] = ['Jim Lemke', 'SJ Rabun']
      end

      it 'finds no errors' do
        expect(service.verify).to eq([])
      end
    end

    context 'when a label is missing' do
      it 'logs the error' do
        expect(service.verify).to include("fetch labels error: #{pid}, photographer")
      end
    end

    context 'when a combined label is missing' do
      before do
        solr_doc['photographer_label_sim'] = ['Jim Lemke']
      end

      it 'logs the error' do
        expect(service.verify).to include("combined_label error: #{pid}, creator")
      end
    end

    context 'when a combined label is incomplete' do
      before do
        properties << { name: 'illustrator_label', is_controlled: true, collection_facetable: true }
        solr_doc['photographer_label_sim'] = ['Jim Lemke']
        solr_doc['illustrator_sim'] = ['http://opaquenamespace.org/ns/creators/RabunSJ']
        solr_doc['illustrator_label_sim'] = ['SJ Rabun']
        solr_doc['creator_combined_label_sim'] = ['Jim Lemke']
      end

      it 'logs the error' do
        expect(service.verify).to include("combined_label error: #{pid}, creator")
      end
    end
  end
end
