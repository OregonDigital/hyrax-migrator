# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Jobs::MigrateWorkJob do
  let(:job) { described_class.new(pid: pid, file_path: file_path) }
  let!(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:pid) { 'abcde1234' }
  let(:file_path) { 'tmp/test_file.zip' }

  it { expect(job.work).to eq work }
  it { expect(job.middleware).to be_a Hyrax::Migrator::Middleware::DefaultMiddleware }

  describe 'creating a new work while running the job' do
    let(:job) { described_class.new(pid: new_pid, file_path: file_path) }
    let(:new_pid) { 'newonehere' }

    it { expect(job.work.pid).to eq new_pid }
  end

  describe 'running the job' do
    let(:middleware) { double }

    before do
      allow(job).to receive(:middleware).and_return(middleware)
    end

    it do
      allow(middleware).to receive(:start).with(work).and_return(true)
      expect(job).to receive(:work).and_return(work)
      job.run
    end
    it do
      allow(job).to receive(:work).and_return(work)
      expect(middleware).to receive(:start).with(work)
      job.run
    end
  end
end
