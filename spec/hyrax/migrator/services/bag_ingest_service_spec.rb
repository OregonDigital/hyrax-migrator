# frozen_string_literal:true

require 'byebug'

RSpec.describe Hyrax::Migrator::Services::BagIngestService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:batch_name) { 'batch1' }
  let(:batch_dir_names) { [batch_name] }
  let(:service) { described_class.new(batch_dir_names, config) }
  let(:location_service) { instance_double('Hyrax::Migrator::Services::BagFileLocationService') }
  let(:all_bags_dir) { File.join(Rails.root, '..', 'fixtures') }

  before do
    allow(Hyrax::Migrator::Services::BagFileLocationService).to receive(:new).and_return(location_service)
    allow(location_service).to receive(:bags_to_ingest).and_return(
      'batch1' => ['/data/tmp/batch1/df70bm35k.zip', '/data/tmp/batch1/df65vc341.zip', '/data/tmp/batch1/df65vc936.zip']
    )
    config.ingest_local_path = all_bags_dir
    config.ingest_storage_service = :file_system
    config.aws_s3_app_key = 'test'
    config.aws_s3_app_secret = 'test'
    config.aws_s3_ingest_bucket = 'my-ingest-bucket'
    config.aws_s3_region = 'test'
    config.aws_s3_url_availability = 86_400
  end

  describe '#ingest' do
    context 'when ingest_storage_service is :file_system' do
      before do
        config.ingest_storage_service = :file_system
        ActiveJob::Base.queue_adapter = :test
      end

      it 'enqueues one job for each bag in batch_name for migration' do
        service.ingest
        expect(Hyrax::Migrator::Jobs::MigrateWorkJob).to have_been_enqueued.exactly(3).times
      end
    end
  end
end
