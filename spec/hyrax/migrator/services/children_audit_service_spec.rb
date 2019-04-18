# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::ChildrenAuditService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { described_class.new(work, config) }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:pid) { '3t945r08v' }

  describe '#audit' do
    let(:env) do
      { children: {
        '0' => { 'id' => 'abcde1234' },
        '1' => { 'id' => 'abcde1235' },
        '2' => { 'id' => 'abcde1236' }
      } }
    end
    let(:asset) { double }

    context 'when all the children are present' do
      before do
        allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(asset)
        work.env = env
      end

      it 'returns true' do
        expect(service.audit).to eq(true)
      end
    end

    context 'when some children are missing' do
      before do
        allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).with('abcde1234').and_return(asset)
        allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).with('abcde1235').and_return(asset)
        allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).with('abcde1236').and_return(nil)
        work.env = env
      end

      it 'returns 2' do
        expect(service.audit).to eq(2)
      end
    end
  end
end
