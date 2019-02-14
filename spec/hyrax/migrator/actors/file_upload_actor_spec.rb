# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::FileUploadActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid, file_path: File.join(Rails.root, '..', 'fixtures', pid)) }
  let(:pid) { '3t945r08v' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { instance_double('Hyrax::Migrator::Services::FileUploadService') }
  let(:aws_signed_url) { "https://www.example.com/#{basename_content_file}" }
  let(:basename_content_file) { "#{pid}_content.jpeg" }
  let(:filesystem_path) { File.join(Rails.root, 'tmp') }
  let(:local_filename) { File.join(filesystem_path, basename_content_file) }
  let(:hyrax_uploaded_file) { instance_double('Hyrax::UploadedFile', id: 0) }
  let(:remote_file_hash) do
    {
      'url' => aws_signed_url,
      'file_name' => basename_content_file
    }
  end
  let(:local_file_hash) do
    {
      'local_filename' => local_filename,
      'local_file_uri' => URI.join('file:///', local_filename)
    }
  end

  before do
    allow(actor).to receive(:config).and_return(config)
    allow(Hyrax::Migrator::Services::FileUploadService).to receive(:new).and_return(service)
  end

  describe '#create' do
    context 'when the content file is successfully uploaded to a remote location' do
      before do
        allow(service).to receive(:upload_file_content).and_return(remote_file_hash)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('file_upload_succeeded')
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the content file is successfully uploaded to the local file system' do
      before do
        allow(service).to receive(:upload_file_content).and_return(local_file_hash)
        allow(actor).to receive(:hyrax_local_file_uploaded).and_return(hyrax_uploaded_file)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('file_upload_succeeded')
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the file_upload_service fails' do
      let(:error) { StandardError }

      before do
        allow(service).to receive(:upload_file_content).and_raise(error)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('file_upload_failed')
      end
      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
    end
  end
end
