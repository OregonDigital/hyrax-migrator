# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerificationService do
  let(:service) { described_class.new(pid, services) }
  let(:pid) { 'abcde1234' }
  let(:work) { double }
  let(:asset) { double }
  let(:working_dir) { 'path_to_somewhere' }
  let(:original_profile) { double }
  let(:services) { [FakeService] }
  let(:fake_service) { double }
  let(:migrated_work) { MigratedWork.new(pid) }
  let(:error_message) { 'there is an anomaly in the space-time continuum' }

  class FakeService
    def initialize(migrated_work); end
  end

  before do
    allow(Hyrax::Migrator::Work).to receive(:find_by).and_return(work)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(asset)
    allow(work).to receive(:working_directory).and_return(working_dir)
    allow(work).to receive(:pid).and_return(pid)
    allow(YAML).to receive(:load_file).and_return(original_profile)
    allow(FakeService).to receive(:new).and_return(fake_service)
    allow(fake_service).to receive(:verify).and_return error_message
    allow(work).to receive(:remove_temp_directory)
  end

  describe '#verify' do
    context 'when a verifier returns an error' do
      it 'passes the error on' do
        expect(service.verify).to eq([error_message])
      end
    end
  end
end
