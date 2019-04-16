# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Jobs::MigrateWorkJob, type: :job do
  include ActiveJob::TestHelper

  let!(:job) { described_class.perform_later(pid: pid, file_path: file_path) }
  let(:pid) { 'abcde1234' }
  let(:file_path) { 'tmp/test_file.zip' }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it { expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1 }
end
