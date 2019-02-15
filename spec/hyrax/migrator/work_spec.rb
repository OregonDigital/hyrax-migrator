# frozen_string_literal:true

require 'zip'

RSpec.describe Hyrax::Migrator::Work do
  let(:model) { create(:work) }
  let(:zip_file) { File.join(Rails.root, 'tmp', "test-#{Time.now.to_i}.zip") }

  it { expect(model.env).to be_a Hash }
  it { expect(described_class::SUCCESS).to eq('success') }
  it { expect(described_class::FAIL).to eq('fail') }
  it { expect(model.working_directory).to eq model[:file_path] }
  it { expect(model.remove_temp_directory).to be_truthy }

  context 'with a temporary directory containing the unzipped file' do
    before do
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
end
