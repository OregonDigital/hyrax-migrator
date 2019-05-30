# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::FileIdentityActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work_file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid) }
  let(:test_checksum) do
    {
      file_name: 'test',
      checksum: 'test',
      checksum_encoding: 'sha1'
    }
  end
  let(:service) { instance_double('Hyrax::Migrator::Services::LoadFileIdentityService') }

  let(:pid) { 'abcde1234' }

  describe '#create' do
    context 'when the validation succeeds' do
      before do
        allow(Hyrax::Migrator::Services::LoadFileIdentityService).to receive(:new).and_return(service)
        allow(service).to receive(:content_file_checksums).and_return([test_checksum])
        allow(work).to receive(:working_directory).and_return(work_file_path)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('file_identity_succeeded')
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the validation fails' do
      let(:error) { StandardError }
      let(:work_file_path) { 'unknown-path' }

      before do
        allow(service).to receive(:content_file_checksums).and_raise(error)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('file_identity_failed')
      end
      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
    end

    context 'when the process blows up' do
      let(:error) { StandardError.new('my-error') }

      before do
        allow(service).to receive(:content_file_checksums).and_raise(error)
        actor.next_actor = terminal
      end

      it 'logs the failure' do
        expect(Rails.logger).to receive(:warn)
        actor.create(work)
      end
    end
  end
end
