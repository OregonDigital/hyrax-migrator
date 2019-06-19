# frozen_string_literal:true

require 'byebug'

RSpec.describe Hyrax::Migrator::Services::BagFileLocationService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:batch_name) { 'batch1' }
  let(:batch_dir_names) { [batch_name] }
  let(:service) { described_class.new(batch_dir_names, config) }
  let(:all_bags_dir) { File.join(Rails.root, '..', 'fixtures') }
  let(:batch_local_path) { File.join(all_bags_dir, batch_name) }
  let(:bag1) { File.join(all_bags_dir, batch_name, 'df65vc341.zip') }
  let(:bag2) { File.join(all_bags_dir, batch_name, 'df65vc936.zip') }
  let(:bag3) { File.join(all_bags_dir, batch_name, 'df70bm35k.zip') }

  before do
    config.ingest_local_path = all_bags_dir
    config.ingest_storage_service = :file_system
    config.aws_s3_app_key = 'test'
    config.aws_s3_app_secret = 'test'
    config.aws_s3_ingest_bucket = 'my-ingest-bucket'
    config.aws_s3_region = 'test'
    config.aws_s3_url_availability = 86_400
  end

  describe '#bags_to_ingest' do
    context 'when ingest_storage_service is :file_system' do
      before do
        config.ingest_storage_service = :file_system
      end

      it 'returns all bags in batch1 folder to ingest' do
        expect(service.bags_to_ingest[batch_name]).to include(bag1, bag2, bag3)
      end
    end

    context 'when ingest_storage_service is :aws_s3' do
      let(:zip_bag1) { "#{batch_name}/df65vc341.zip" }
      let(:zip_bag2) { "#{batch_name}/df65vc936.zip" }
      let(:zip_bag3) { "#{batch_name}/df70bm35k.zip" }

      let(:base_signed_url_bag1) { "https://my-ingest-bucket.s3.test.amazonaws.com/#{zip_bag1}" }
      let(:base_signed_url_bag2) { "https://my-ingest-bucket.s3.test.amazonaws.com/#{zip_bag2}" }
      let(:base_signed_url_bag3) { "https://my-ingest-bucket.s3.test.amazonaws.com/#{zip_bag3}" }

      let(:bag1_obj) { Aws::S3::Object.new(bucket_name: config.aws_s3_ingest_bucket, key: zip_bag1, access_key_id: config.aws_s3_app_key, secret_access_key: config.aws_s3_app_secret, region: config.aws_s3_region) }
      let(:bag2_obj) { Aws::S3::Object.new(bucket_name: config.aws_s3_ingest_bucket, key: zip_bag2, access_key_id: config.aws_s3_app_key, secret_access_key: config.aws_s3_app_secret, region: config.aws_s3_region) }
      let(:bag3_obj) { Aws::S3::Object.new(bucket_name: config.aws_s3_ingest_bucket, key: zip_bag3, access_key_id: config.aws_s3_app_key, secret_access_key: config.aws_s3_app_secret, region: config.aws_s3_region) }

      before do
        config.ingest_storage_service = :aws_s3
        allow(service).to receive(:aws_s3_objects).with(batch_name).and_return([bag1_obj, bag2_obj, bag3_obj])
      end

      it 'returns all bags in batch1 folder to ingest' do
        expect(service.bags_to_ingest[batch_name]).to include(match(/#{base_signed_url_bag1}/), match(/#{base_signed_url_bag2}/), match(/#{base_signed_url_bag3}/))
      end
    end

    context 'when ingest_storage_service is :file_system and batch folders don\'t exist' do
      before do
        config.ingest_storage_service = :file_system
        allow(File).to receive(:directory?).with(batch_local_path).and_return(false)
      end

      it 'returns all bags in batch1 and batch2 folder to ingest' do
        expect { service.bags_to_ingest }.to raise_error(StandardError)
      end
    end

    context 'when ingest_storage_service is :file_system and a single batch folder doesn\'t exist' do
      before do
        config.ingest_storage_service = :file_system
        allow(Dir).to receive(:entries).with(batch_local_path).and_raise(Errno::ENOENT)
      end

      it 'returns all bags in batch1 and batch2 folder to ingest' do
        expect { service.bags_to_ingest }.to raise_error(StandardError)
      end
    end
  end
end
