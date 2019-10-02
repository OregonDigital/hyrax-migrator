# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::ListChildrenService do
  let(:pid) { '3t945r08v' }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:service) { described_class.new(work, config) }
  let(:result_hash) do
    h = {}
    h['0'] = { 'id' => 'abcde1234' }
    h['1'] = { 'id' => 'abcde1235' }
    h
  end
  let(:resource1) { 'http://oregondigital.org/resource/oregondigital:abcde1234' }
  let(:resource2) { 'http://oregondigital.org/resource/oregondigital:abcde1235' }

  before do
    work.env[:attributes] = {}
    work.env[:attributes][:contents] = [resource1, resource2]
  end

  describe 'list_children' do
    context 'when there are children' do
      it 'puts them in a hash, in order' do
        expect(service.list_children).to eq(result_hash)
      end
    end

    context 'when the object is not an oregondigital resource uri' do
      let(:resource1) { '_:g11112223333444455555' }
      let(:resource2) { '_:g66666777778888899999' }

      it 'skips it' do
        expect(service.list_children).to be_empty
      end
    end

    context 'when there are no children' do
      before do
        work.env[:attributes] = {}
      end

      it 'returns an empty hash' do
        expect(service.list_children).to be_empty
      end
    end
  end
end
