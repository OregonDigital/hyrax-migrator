# frozen_string_literal: true

require 'byebug'

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
      before do
        config.upload_storage_service = :file_system
      end

      it 'returns the content file path' do
        expect(service.upload_file_content['local_filename']).to eq File.join(work_file_path, 'data', basename_content_file)
      end
    end

    context 'when upload service is :file_system and upload_to_file_system fails with file not found' do
      before do
        config.upload_storage_service = :file_system
        allow(service).to receive(:upload_to_file_system).and_raise(StandardError.new('file not found'))
      end

      it 'raises file not found error' do
        expect { service.upload_file_content }.to raise_error(StandardError, 'file not found')
      end
    end

    context 'when upload service is :file_system and content file is not found' do
      before do
        config.upload_storage_service = :file_system
        stub_const('Hyrax::Migrator::Services::FileUploadService::CONTENT_FILE', 'invalid')
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn)
        service.send(:content_file)
      end

      it 'returns nil' do
        expect(service.send(:content_file)).to be_nil
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
        :get_object,
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

    context 'when upload service is :aws_s3 and upload_to_s3 fails' do
      before do
        config.upload_storage_service = :aws_s3
        allow(service).to receive(:upload_to_s3).and_raise(StandardError.new('file not found'))
      end

      it 'raises file not found error' do
        expect { service.upload_file_content }.to raise_error(StandardError, 'file not found')
      end
    end

    context 'when upload service is :aws_s3 and upload_to_s3 fails with aws s3 errors' do
      before do
        config.upload_storage_service = :aws_s3
      end

      it 'raises timeout error' do
        allow(Aws::S3::Client).to receive(:new) { s3_client }.and_raise(Aws::S3::Errors::Timeout)
        expect { service.upload_file_content }.to raise_error(StandardError)
      end

      it 'raises not found error' do
        allow(Aws::S3::Client).to receive(:new) { s3_client }.and_raise(Aws::S3::Errors::NotFound)
        expect { service.upload_file_content }.to raise_error(StandardError)
      end
    end
  end
end
