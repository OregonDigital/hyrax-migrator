# frozen_string_literal: true

require 'byebug'

RSpec.describe Hyrax::Migrator::Services::WorkflowMetadataService do
  let(:pid) { 'fx719n867' }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:service) { described_class.new(work) }
  let(:asset) { double }

  describe '#workflow_profile' do
    before do
      allow(service).to receive(:asset).and_return(asset)
      allow(service).to receive(:update_asset).and_return(true)
    end

    context 'when workflowMetadata profile is available' do
      it 'returns a hash with workflowMetadata profile values' do
        expect(service.workflow_profile).to include('dsCreateDate')
      end
    end

    context 'when {pid}_workflowMetadata_profile.yml doesn\'t exist' do
      let(:error) { StandardError }
      let(:file_path) { 'unknown-path' }

      it 'raises an error' do
        expect { service.workflow_profile }.to raise_error(error)
      end
    end
  end
end
