RSpec.describe Hyrax::Migrator::FileUploadService do


  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { described_class.new("test file", config) } 

  before do
    config.file_system_path = "/data/tmp"
    config.aws_s3_app_key = "test"
    config.aws_s3_app_secret = "test"
    config.aws_s3_bucket = "test"
    config.aws_s3_region = "test"
  end

  describe 'upload_file_content' do
    # TODO: retrieve proper fixture to test and implement specs for uploading files based on environment
    it 'uploads content to proper destination' do
      expect(service.send(:upload_file_content)).to eq true
    end
  end
end
