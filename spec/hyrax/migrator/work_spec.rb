# frozen_string_literal:true

require 'zip'

RSpec.describe Hyrax::Migrator::Work do
  let(:model) { create(:work) }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:zip_file) { File.join(Rails.root, 'tmp', "test-#{Time.now.to_i}.zip") }

  it { expect(model.env).to be_a Hash }
  it { expect(described_class::SUCCESS).to eq('success') }
  it { expect(described_class::FAIL).to eq('fail') }
  it { expect(model.working_directory).to eq model[:file_path] }
  it { expect(model.remove_temp_directory).to be_truthy }

  context 'with a temporary directory containing the unzipped file' do
    before do
      Hyrax::Migrator.config.file_system_path = '/tmp'
      Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
        zipfile.add('Gemfile', File.join(Rails.root, '../../Gemfile'))
      end
      model[:file_path] = zip_file
    end

    after do
      File.unlink(zip_file)
    end

    it { expect(model.working_directory).not_to eq(zip_file) }
    it { expect(model.remove_temp_directory).to be_truthy }
  end

  context 'with a remote file in an S3 bucket' do
    let(:s3_client) { instance_spy('s3 client') }
    let(:url) { 'http://s3-us-west2.amazonaws.com/bob/ross/is/the/best.zip' }
    let(:uri) { URI.parse(url) }
    # ross/is/the/best.zip
    let(:s3_key) { uri.path.split('/')[2..-1].join('/') }
    # bob
    let(:s3_bucket) { uri.path.split('/')[1] }
    let(:model) { create(:work, file_path: url) }

    before do
      config.aws_s3_app_key = 'test'
      config.aws_s3_app_secret = 'test'
      config.aws_s3_region = 'test'
      allow(model).to receive(:temporary_directory).and_return('/some/directory/blah')
      allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
      allow(s3_client).to receive(:get_object).with(
        response_target: '/some/directory/blah/best.zip',
        bucket: s3_bucket,
        key: s3_key
      ).and_return(true)
      # mock the extracting of the downloaded zip file
      allow(model).to receive(:extract_local_zip).and_return('/a/new/random/unzipped/path/blah')
    end

    it { expect(model.working_directory).to eq '/a/new/random/unzipped/path/blah' }

    context 'with an exception downloading the remote file' do
      before do
        allow(model).to receive(:aws_s3_fetch_object).and_raise('boom goes the dynamite')
      end

      it { expect { model.working_directory }.to raise_exception('boom goes the dynamite') }
    end
  end
end
