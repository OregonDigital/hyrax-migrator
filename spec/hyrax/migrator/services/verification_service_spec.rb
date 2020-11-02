# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerificationService do
  let(:migrator_work) { double }
  let(:hyrax_work) { double }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:original_profile) { YAML.load_file("spec/fixtures/data/#{pid}_profile.yml") }
  let(:service) { described_class.new(migrator_work, config, 'spec/fixtures/data') }
  let(:pid) { 'df70jh899' }
  let(:metadata_service) { double }
  let(:checksums_service) { double }
  let(:derivatives_service) { double }
  let(:children_service) { double }

  before do
    allow(migrator_work).to receive(:pid).and_return(pid)
    allow(Hyrax::Migrator::Services::VerifyMetadataService).to receive(:new).and_return(metadata_service)
    allow(Hyrax::Migrator::Services::VerifyChecksumsService).to receive(:new).and_return(checksums_service)
    allow(Hyrax::Migrator::Services::VerifyDerivativesService).to receive(:new).and_return(derivatives_service)
    allow(Hyrax::Migrator::Services::VerifyChildrenService).to receive(:new).and_return(children_service)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(hyrax_work)
  end

  describe 'verify' do
    context 'when a service returns an error' do
      before do
        allow(metadata_service).to receive(:verify_metadata).and_return(["Unable to verify identifier in #{pid}."])
        allow(checksums_service).to receive(:verify_content).and_return([])
        allow(derivatives_service).to receive(:verify).and_return([])
        allow(children_service).to receive(:verify_children).and_return([])
        allow(migrator_work).to receive(:remove_temp_directory)
      end

      it 'passes the error on' do
        expect(service.verify).to eq([["Unable to verify identifier in #{pid}."], [], [], []])
      end

      it 'removes the temp directory' do
        expect(migrator_work).to receive(:remove_temp_directory)
        service.verify
      end
    end

    context 'when an error is raised' do
      let(:error) { StandardError }

      before do
        allow(metadata_service).to receive(:verify_metadata).and_return([])
        allow(checksums_service).to receive(:verify_content).and_return([])
        allow(derivatives_service).to receive(:verify).and_raise(error, 'Fail')
        allow(migrator_work).to receive(:remove_temp_directory)
      end

      it 'handles the error' do
        expect(service.verify).to eq([[], [], "Encountered an error while working on #{pid}: Fail"])
      end

      it 'removes the temp directory' do
        expect(migrator_work).to receive(:remove_temp_directory)
        service.verify
      end
    end
  end
end
