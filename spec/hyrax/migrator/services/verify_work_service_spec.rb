# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyWorkService do
  let(:service) { described_class.new(pid: pid) }
  let(:verification_service) { double }
  let(:work) { create(:work, pid: pid, env: {}) }
  let(:pid) { 'abcde1234' }
  let(:message) { 'Houston, we have a problem' }

  describe 'running the service when there are errors' do
    before do
      allow(Hyrax::Migrator::Services::VerificationService).to receive(:new).and_return(verification_service)
      allow(verification_service).to receive(:verify).and_return([message])
      allow(Hyrax::Migrator::Work).to receive(:find_by).and_return(work)
    end

    it 'adds the error to the work' do
      service.run
      expect(work.env[:verification_errors]).to eq([message])
    end
  end

  describe 'running the service when there are no errors' do
    before do
      allow(Hyrax::Migrator::Services::VerificationService).to receive(:new).and_return(verification_service)
      allow(verification_service).to receive(:verify).and_return([])
      allow(Hyrax::Migrator::Work).to receive(:find_by).and_return(work)
    end

    it 'returns without editing the work' do
      service.run
      expect(work).not_to receive(:save)
    end
  end
end
