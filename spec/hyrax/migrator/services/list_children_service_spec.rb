# frozen_string_literal: true

require 'rdf'
require 'rdf/ntriples'

RSpec.describe Hyrax::Migrator::Services::ListChildrenService do
  let(:pid) { 'df72jn67c' }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:service) { described_class.new(work, config) }
  let(:result_hash) do
    h = {}
    h['0'] = { 'id' => 'df72jn000' }
    h['1'] = { 'id' => 'df72jn018' }
    h
  end
  let(:resource1) { 'http://oregondigital.org/resource/oregondigital:df72jn000' }
  let(:resource2) { 'http://oregondigital.org/resource/oregondigital:df72jn018' }

  describe 'list_children' do
    context 'when there are children' do
      it 'puts them in a hash, in order' do
        expect(service.list_children).to eq(result_hash)
      end
    end

    context 'when there are no children' do
      let(:path) { 'spec/fixtures/3t945r08v/data/3t945r08v_descMetadata.nt' }

      before do
        allow(service).to receive(:nt_path).and_return(path)
      end

      it 'returns an empty hash' do
        expect(service.list_children).to be_empty
      end
    end
  end
end
