# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::HyraxCore::UploadedFile do
  let(:hyrax_uploaded_file) { described_class.new(user: migration_user_instance, uploaded_file_uri: uploaded_file_uri, uploaded_filename: local_filename) }
  let(:migration_user_instance) { instance_double('User') }
  let(:uploaded_file_uri) { URI.join('file:///', local_filename) }
  let(:basename_content_file) { "#{pid}_content.jpeg" }
  let(:filesystem_path) { File.join(Rails.root, 'tmp') }
  let(:local_filename) { File.join(filesystem_path, basename_content_file) }
  let(:actor_environment) { double }
  let(:hyrax_uploaded_file_instance) { double }

  describe '#create' do
    context 'when it raises an error' do
      before do
        allow(hyrax_uploaded_file).to receive(:create_uploaded_file).and_raise('error')
      end

      it { expect { hyrax_uploaded_file.create }.to raise_error('error') }
    end

    context 'when it succeeds' do
      before do
        allow(hyrax_uploaded_file).to receive(:create_uploaded_file).and_return(hyrax_uploaded_file_instance)
      end

      it { expect(hyrax_uploaded_file.create).to eq hyrax_uploaded_file_instance }
    end

    context 'when it fails' do
      before do
        allow(hyrax_uploaded_file).to receive(:create_uploaded_file).and_return(nil)
      end

      it { expect(hyrax_uploaded_file.create).to eq false }
    end
  end
end
