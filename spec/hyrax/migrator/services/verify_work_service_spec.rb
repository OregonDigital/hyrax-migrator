# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyWorkService do
  let(:service) { described_class.new(args) }
  let(:args) { { pid: pid } }
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

  describe 'running the service with a custom list of services' do
    let(:args) { { pid: pid, verify_services: ['Hyrax::Migrator::Services::VerifyMetadataService'] } }
    let(:verify_metadata_service) { double }
    let(:migrated_work) { double }

    before do
      allow(Hyrax::Migrator::Services::VerificationService::MigratedWork).to receive(:new).and_return(migrated_work)
      allow(Hyrax::Migrator::Services::VerifyMetadataService).to receive(:new).and_return(verify_metadata_service)
      allow(verify_metadata_service).to receive(:verify).and_return([])
      allow(verification_service).to receive(:verify).and_return([])
      allow(migrated_work).to receive(:work).and_return(work)
    end

    it 'only instantiates VerifyMetadataService' do
      expect(Hyrax::Migrator::Services::VerifyChecksumsService).not_to receive :new
      expect(Hyrax::Migrator::Services::VerifyMetadataService).to receive :new
      service.run
    end
  end
end
