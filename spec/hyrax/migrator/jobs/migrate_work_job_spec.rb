# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Jobs::MigrateWorkJob, type: :job do
  include ActiveJob::TestHelper

  let(:pid) { 'abcde1234' }
  let(:file_path) { 'tmp/test_file.zip' }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'performs job' do
    expect(Rails.logger).to receive(:info).at_least(:twice)
    perform_enqueued_jobs do
      described_class.perform_later(pid: pid, file_path: file_path)
    end
    assert_performed_jobs 1
  end
end
