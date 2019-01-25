RSpec.describe Hyrax::Migrator::FileUploadService do
  let(:service) { described_class.new("test file") } 
  describe 'upload_file_content' do
    # TODO: retrieve proper fixture to test and implement specs for uploading files based on environment
    it 'uploads content to proper destination' do
      expect(service.send(:upload_file_content)).to eq true
    end
  end
end
