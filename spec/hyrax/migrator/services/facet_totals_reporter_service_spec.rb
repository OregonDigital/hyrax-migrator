# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::FacetTotalsReporterService do
  class Facet
    attr_accessor :solr_name, :label
  end
  let(:service) { described_class.new('coll123') }
  let(:search_service) { instance_double('Hyrax::Migrator::HyraxCore::SearchService') }
  let(:facet_results) do
    { 'facet_counts' =>
    { 'facet_fields' =>
    { 'workType_label_sim' =>
    ['colour photographs', 1,
     'photomicrographs', 1,
     'slides (photographs)', 1,
     'stamps (exchange media)', 1,
     'tax stamps', 1] } } }
  end
  let(:collection) { instance_double('Collection', id: 'ohba') }
  let(:facets) do
    f = Facet.new
    f.solr_name = 'workType_label_sim'
    f.label = 'Work Type'
    [f]
  end
  let(:test_io) { StringIO.new }

  before do
    allow(Hyrax::Migrator::HyraxCore::SearchService).to receive(:new).and_return(search_service)
    allow(search_service).to receive(:search).and_return(facet_results)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(collection)
    allow(collection).to receive(:available_facets).and_return(facets)
    allow(File).to receive(:open).and_return test_io
  end

  describe '#create_report' do
    it 'writes the totals for the facets' do
      service.create_report
      expect(test_io.string).to include "workType_label_sim\tcolour photographs\t1"
    end
  end
end
