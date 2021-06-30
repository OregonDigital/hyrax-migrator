# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::BatchUpdateService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:batch_name) { 'batch1' }
  let(:batch_dir_names) { [batch_name] }
  let(:service) { described_class.new(batch_dir_names, { migrator_config: config, middleware_config: middleware }) }
  let(:middleware) { { actor_stack: ['Hyrax::Migrator::Actors::CrosswalkMetadataActor', 'Hyrax::Migrator::Actors::UpdateWorkActor'] } }
  let(:location_service) { instance_double('Hyrax::Migrator::Services::BagFileLocationService') }
  let(:all_bags_dir) { File.join(Rails.root, '..', 'fixtures') }
  let(:work) { Hyrax::Migrator::Work.create(pid: 'df65vc341', file_path: 'path') }
  let(:bag1) { File.join(all_bags_dir, batch_name, 'df65vc341.zip') }
  let(:baggit_bag) { double }

  before do
    allow(Hyrax::Migrator::Services::BagFileLocationService).to receive(:new).and_return(location_service)
    allow(location_service).to receive(:bags_to_ingest).and_return(
      'batch1' => [bag1]
    )
    config.ingest_local_path = all_bags_dir
    config.ingest_storage_service = :file_system
  end

  describe '#update' do
    before do
      ActiveJob::Base.queue_adapter = :test
      allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:exists?).with(anything).and_return(true)
      allow(Hyrax::Migrator::Work).to receive(:find_by).and_return(work)
      allow(BagIt::Bag).to receive(:new).and_return(baggit_bag)
      allow(baggit_bag).to receive(:bag_info).and_return({ 'Bagging-Date' => '2021-03-02' })
      allow(work).to receive(:updated_at).and_return Time.local('2021-02-01').in_time_zone
      allow(service).to receive(:parse_pid).and_return('abcde1234')
    end

    context 'when ingest_storage_service is :file_system' do
      before do
        config.ingest_storage_service = :file_system
      end

      it 'enqueues one job for each bag in batch_name for migration' do
        service.update
        expect(Hyrax::Migrator::Jobs::MigrateWorkJob).to have_been_enqueued.exactly(1).times
      end
    end
  end
end
