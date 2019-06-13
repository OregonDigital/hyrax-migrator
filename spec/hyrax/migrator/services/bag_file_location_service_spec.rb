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
  end

  describe '#bags_to_ingest' do
    context 'when ingest_storage_service is :file_system' do
      before do
        config.ingest_storage_service = :file_system
      end

      it 'returns all bags in batch1 and batch2 folder to ingest' do
        expect(service.bags_to_ingest[batch_name]).to include(bag1, bag2, bag3)
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
