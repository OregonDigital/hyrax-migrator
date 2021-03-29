# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::FacetReporterService do
  class Facet
    attr_accessor :solr_name, :label
  end
  let(:service) { described_class.new('batch123') }
  let(:location_service) { instance_double('Hyrax::Migrator::Services::BagFileLocationService') }
  let(:bag1) { double }
  let(:collection) { instance_double('Collection', id: 'ohba') }
  let(:solr_record) do
    { :id => 'fx719p24f',
      'member_of_collection_ids_ssim' => %w[osu-scarc ohba],
      'workflow_state_name_ssim' => 'pending_review',
      'workType_label_sim' => %w[colour_photographs photomicrographs] }
  end
  let(:facets) do
    f = Facet.new
    f.solr_name = 'workType_label_sim'
    f.label = 'Work Type'
    [f]
  end
  let(:test_io) { StringIO.new }

  before do
    allow(Hyrax::Migrator::Services::BagFileLocationService).to receive(:new).and_return(location_service)
    allow(location_service).to receive(:bags_to_ingest).and_return({ 'batch123' => ['fx719p24f.zip'] })
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:solr_record).and_return(solr_record)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(collection)
    allow(collection).to receive(:available_facets).and_return(facets)
    allow(File).to receive(:open).and_return test_io
  end

  describe '#create_report' do
    it 'writes a file' do
      service.create_report
      expect(test_io.string).to include 'fx719p24f'
    end

    context 'when there is not a solr record' do
      before do
        allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:solr_record).and_return([])
      end

      it 'logs the pid' do
        service.create_report
        expect(test_io.string).to include("assets not found:\nfx719p24f")
      end
    end
  end

  describe  '#add_collections' do
    context 'when the solr record has no collection' do
      let(:solr_asset) { { 'member_of_collection_ids_ssim' => [] } }

      it 'stops, does not call find' do
        expect(Hyrax::Migrator::HyraxCore::Asset).not_to receive(:find)
        service.send(:add_collections, solr_asset)
      end
    end

    context 'when there are collections' do
      let(:solr_asset) { { 'member_of_collection_ids_ssim' => %w[mycoll1 mycoll2] } }

      context 'when the collection is already known' do
        let(:colls) { %w[mycoll1 mycoll2 mycoll3] }

        before do
          service.instance_variable_set(:@collections, colls)
        end

        it 'skips, does not call find' do
          expect(Hyrax::Migrator::HyraxCore::Asset).not_to receive(:find)
          service.send(:add_collections, solr_asset)
        end
      end

      context 'when the collection is not known' do
        it 'adds the collection' do
          service.send(:add_collections, solr_asset)
          expect(service.instance_variable_get(:@collections)).to include('mycoll1')
        end
      end
    end
  end
end
