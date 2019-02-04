require 'byebug'
RSpec.describe Hyrax::Migrator::Services::FileUploadService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { described_class.new(work.file_path, config) } 
  let(:pid) { '3t945r08v' }
  let(:work) { create(:work, pid: pid, file_path: File.join(Rails.root, '..', 'fixtures', pid)) }

  before do
    config.file_system_path = "/data/tmp"
    config.aws_s3_app_key = "test"
    config.aws_s3_app_secret = "test"
    config.aws_s3_bucket = "test"
    config.aws_s3_region = "test"
  end

  describe '#upload_file_content' do
    # TODO: retrieve proper fixture to test and implement specs for uploading files based on environment
    it 'uploads content to proper destination' do
      # byebug
      expect(service.send(:upload_file_content)).to eq true
    end
  end
end
