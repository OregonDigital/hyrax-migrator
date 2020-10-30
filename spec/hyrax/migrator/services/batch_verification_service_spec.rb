# frozen_string_literal:true

require 'byebug'

RSpec.describe Hyrax::Migrator::Services::BatchVerificationService do
  let(:batch_name) { 'batch1' }
  let(:service) { described_class.new(batch_name) }
  let(:location_service) { instance_double('Hyrax::Migrator::Services::BagFileLocationService') }
  let(:all_bags_dir) { File.join(Rails.root, '..', 'fixtures') }
  let(:bag1) { File.join(all_bags_dir, batch_name, 'df65vc341.zip') }

  before do
    allow(Hyrax::Migrator::Services::BagFileLocationService).to receive(:new).and_return(location_service)
    allow(location_service).to receive(:bags_to_ingest).and_return(
      'batch1' => [bag1]
    )
  end

  describe '#verify' do
    before do
      ActiveJob::Base.queue_adapter = :test
    end

    context 'when given a batch' do
      it 'enqueues one job for each bag in batch_name' do
        service.verify
        expect(Hyrax::Migrator::Jobs::VerifyWorkJob).to have_been_enqueued.exactly(1).times
      end
    end
  end
end
