# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::ChildrenAuditService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { described_class.new(work, config) }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:pid) { '3t945r08v' }

  describe '#audit' do
    let(:env) do
      { work_members_attributes: {
        '0' => { 'id' => 'abcde1234' },
        '1' => { 'id' => 'abcde1235' },
        '2' => { 'id' => 'abcde1236' }
      } }
    end
    let(:asset) { double }

    before do
      allow(asset).to receive(:status).and_return(Hyrax::Migrator::Work::SUCCESS)
      work.env = env
    end

    context 'when all the children are present' do
      before do
        allow(Hyrax::Migrator::Work).to receive(:find_by).and_return(asset)
      end

      it 'returns true' do
        expect(service.audit).to eq(true)
      end
    end

    context 'when one child does not exist' do
      before do
        allow(Hyrax::Migrator::Work).to receive(:find_by).with(pid: 'abcde1234').and_return(asset)
        allow(Hyrax::Migrator::Work).to receive(:find_by).with(pid: 'abcde1235').and_return(asset)
        allow(Hyrax::Migrator::Work).to receive(:find_by).with(pid: 'abcde1236').and_return(nil)
      end

      it 'returns 2' do
        expect(service.audit).to eq(2)
      end
    end

    context 'when one child is not finished' do
      let(:asset2) { double }

      before do
        allow(asset2).to receive(:status).and_return('Im not done yet')
        allow(Hyrax::Migrator::Work).to receive(:find_by).with(pid: 'abcde1234').and_return(asset)
        allow(Hyrax::Migrator::Work).to receive(:find_by).with(pid: 'abcde1235').and_return(asset)
        allow(Hyrax::Migrator::Work).to receive(:find_by).with(pid: 'abcde1236').and_return(asset2)
      end

      it 'returns 2' do
        expect(service.audit).to eq(2)
      end
    end
  end
end
