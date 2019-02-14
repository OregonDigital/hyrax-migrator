# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::FileUploadService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:work_file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: work_file_path) }
  let(:service) { described_class.new(work.file_path, config) }
  let(:pid) { '3t945r08v' }
  let(:basename_content_file) { "#{pid}_content.jpeg" }
  let(:filesystem_path) { File.join(Rails.root, 'tmp') }

  before do
    config.file_system_path = filesystem_path
    config.aws_s3_app_key = 'test'
    config.aws_s3_app_secret = 'test'
    config.aws_s3_bucket = 'my-bucket'
    config.aws_s3_region = 'test'
    config.aws_s3_url_availability = 86_400
  end

  describe '#upload_file_content' do
    context 'when upload service is :file_system' do
      let(:dest_filename) { File.join(config.file_system_path, basename_content_file) }
      let(:dest_filename_obj) do
        {
          'local_file_uri' => URI.join('file:///', dest_filename),
          'local_filename' => '/data/spec/dummy/tmp/3t945r08v_content.jpeg'
        }
      end

      before do
        config.upload_storage_service = :file_system
      end

      it 'returns the destination filename of the content file transfered' do
        expect(service.upload_file_content).to eq dest_filename_obj
      end
    end

    context 'when upload service is :file_system and content file is not found' do
      before do
        config.upload_storage_service = :file_system
        stub_const('Hyrax::Migrator::Services::FileUploadService::CONTENT_FILE', 'invalid')
      end

      it 'raises file not found error' do
        expect { service.send(:content_file) }.to raise_error(StandardError, "could not find a content file in #{work.file_path}/data")
      end
    end

    context 'when upload service is :file_system and data directory is not found' do
      let(:work_file_path) { 'invalid' }

      before do
        config.upload_storage_service = :file_system
      end

      it 'raises data directory not found' do
        expect { service.send(:content_file) }.to raise_error(StandardError, "data directory #{work.file_path}/data not found")
      end
    end
  end

  describe '#upload_to_s3' do
    before do
      config.upload_storage_service = :aws_s3
      allow(Aws::S3::Client).to receive(:new) { s3_client }
      allow(presigner).to receive(:presigned_url).with(
        'get_object',
        bucket: config.aws_s3_bucket,
        key: basename_content_file,
        expires_in: config.aws_s3_url_availability
      ).and_return(aws_signed_url)
      allow(Aws::S3::Presigner).to receive(:new).with(client: s3_client).and_return(presigner)
    end

    let(:s3_client) { instance_spy('s3 client') }
    let(:presigner) { instance_spy('s3 presigner') }
    let(:aws_signed_url) { "https://www.example.com/#{basename_content_file}" }
    let(:remote_file_obj) do
      {
        'url' => aws_signed_url,
        'file_name' => basename_content_file
      }
    end

    it 'returns the signed_url of the new file' do
      expect(service.upload_file_content).to eq remote_file_obj
    end

    context 'when content file not found' do
      let(:work_file_path) { 'invalid' }

      it 'raises data directory not found' do
        expect { service.send(:content_file) }.to raise_error(StandardError, "data directory #{work.file_path}/data not found")
      end
    end
  end
end
