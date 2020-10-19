# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::BatchReporterService do
  let(:batch_name) { 'batch1' }
  let(:service) { described_class.new(batch_name) }
  let(:location_service) { instance_double('Hyrax::Migrator::Services::BagFileLocationService') }
  let(:all_bags_dir) { File.join(Rails.root, '..', 'fixtures') }
  let(:bag1) { File.join(all_bags_dir, batch_name, 'df65vc341.zip') }
  let(:work1) { double }

  before do
    allow(Hyrax::Migrator::Services::BagFileLocationService).to receive(:new).and_return(location_service)
    allow(location_service).to receive(:bags_to_ingest).and_return(
      'batch1' => [bag1]
    )
    allow(Hyrax::Migrator::Work).to receive(:find_by).and_return(work1)
    allow(work1).to receive(:aasm_state).and_return('dandy')
    allow(work1).to receive(:status).and_return('success')
    allow(work1).to receive(:status_message).and_return('doing great')
    allow(work1).to receive(:env).and_return(env)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:exists?).with(anything).and_return(true)
  end

  describe '#write_report' do
    let(:file) { double }
    let(:env) { { errors: [] } }
    let(:message) { "df65vc341: dandy\tsuccess\tdoing great\tno errors\ttrue\n" }

    before do
      allow(File).to receive(:open).and_return(file)
      allow(file).to receive(:puts)
      allow(file).to receive(:close)
    end

    it 'writes the information to a file' do
      expect(file).to receive(:puts).with(message)
      service.write_report
    end
  end

  describe '#screen_report' do
    let(:env) { { errors: ['something minor'] } }
    let(:message) { "df65vc341: dandy\tsuccess\tdoing great\tsomething minor\ttrue\n" }

    it 'writes the report to screen' do
      printed = capture_stdout do
        service.screen_report
      end
      expect(printed).to include(message)
    end
  end
end
