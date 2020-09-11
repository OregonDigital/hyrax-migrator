# frozen_string_literal:true

require 'byebug'

RSpec.describe Hyrax::Migrator::Services::BagIngestService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:batch_name) { 'batch1' }
  let(:batch_dir_names) { [batch_name] }
  let(:service) { described_class.new(batch_dir_names, config) }
  let(:location_service) { instance_double('Hyrax::Migrator::Services::BagFileLocationService') }
  let(:all_bags_dir) { File.join(Rails.root, '..', 'fixtures') }
  let(:bag1) { File.join(all_bags_dir, batch_name, 'df65vc341.zip') }
  let(:bag2) { File.join(all_bags_dir, batch_name, 'df65vc936.zip') }
  let(:bag3) { File.join(all_bags_dir, batch_name, 'df70bm35k.zip') }

  before do
    allow(Hyrax::Migrator::Services::BagFileLocationService).to receive(:new).and_return(location_service)
    allow(location_service).to receive(:bags_to_ingest).and_return(
      'batch1' => [bag1, bag2, bag3]
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
    before do
      ActiveJob::Base.queue_adapter = :test
      allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:exists?).with(anything).and_return(false)
    end

    context 'when ingest_storage_service is :file_system' do
      before do
        config.ingest_storage_service = :file_system
      end

      it 'enqueues one job for each bag in batch_name for migration' do
        service.ingest
        expect(Hyrax::Migrator::Jobs::MigrateWorkJob).to have_been_enqueued.exactly(3).times
      end
    end

    context 'when ingest_storage_service is :file_system and one asset already exists and migration status is fail' do
      before do
        config.ingest_storage_service = :file_system
        allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:exists?).with('df65vc341').and_return(true)
        Hyrax::Migrator::Work.create(pid: 'df65vc341', status: Hyrax::Migrator::Work::FAIL)
      end

      it 'runs all three migrate work jobs' do
        service.ingest
        expect(Hyrax::Migrator::Jobs::MigrateWorkJob).to have_been_enqueued.exactly(3).times
      end
    end

    context 'when ingest_storage_service is :file_system and one asset already exists and migration status is success' do
      before do
        config.ingest_storage_service = :file_system
        allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:exists?).with('df65vc341').and_return(true)
        Hyrax::Migrator::Work.create(pid: 'df65vc341', status: Hyrax::Migrator::Work::SUCCESS)
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn)
        service.ingest
      end

      it 'skips one migrate work job' do
        service.ingest
        expect(Hyrax::Migrator::Jobs::MigrateWorkJob).to have_been_enqueued.exactly(2).times
      end
    end
  end

  describe '#batch_report' do
    before do
      config.ingest_storage_service = :file_system
      allow(location_service).to receive(:bags_to_ingest).and_return('batch1' => [bag1])
      allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:exists?).with('df65vc341').and_return(true)
      Hyrax::Migrator::Work.create(pid: 'df65vc341', status: Hyrax::Migrator::Work::SUCCESS)
    end

    context 'when to_file is false' do
      it 'prints the report to the screen' do
        printed = capture_stdout do
          service.batch_report(batch_name)
        end
        expect(printed).to include('df65vc341')
      end
    end

    context 'when to_file is true' do
      let(:file) { double }

      before do
        allow(File).to receive(:open).and_return file
        allow(file).to receive(:close)
      end

      it 'prints the report to a file' do
        expect(file).to receive(:puts).with("df65vc341: \tsuccess\t\ttrue")
        service.batch_report(batch_name, true)
      end
    end
  end
end
