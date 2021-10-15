# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyChecksumsService do
  let(:hyrax_work) { double }
  let(:migrated_work) { double }
  let(:service) { described_class.new(migrated_work) }
  let(:pid) { 'df70jh899' }
  let(:file_set) { instance_double('FileSet', id: 'bn999672v', uri: 'http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v') }
  let(:content_path) { 'spec/fixtures/data/world.png' }
  let(:original_file) { double }
  let(:original_checksum) { ['28da6259ae5707c68708192a40b3e85c'] }

  before do
    allow(migrated_work).to receive(:asset).and_return(hyrax_work)
    allow(migrated_work).to receive(:working_directory).and_return('some_path')
    allow(migrated_work).to receive(:model_name).and_return('Thing')
    allow(hyrax_work).to receive(:as_json).and_return(json)
    allow(hyrax_work).to receive(:file_sets).and_return([file_set])
    allow(YAML).to receive(:load_file).and_return(YAML.load_file('spec/fixtures/data/df70jh899_checksums.yml'))
    allow(file_set).to receive(:original_file).and_return(original_file)
    allow(original_file).to receive(:original_checksum).and_return(original_checksum)
    allow(hyrax_work).to receive(:id).and_return(pid)
  end

  describe 'verify_content' do
    let(:json) { {} }

    context 'when all checksums values match migrated content' do
      it 'returns no errors' do
        expect(service.verify).to eq([])
      end
    end

    context 'when checksums do not match with migrated content (invalid)' do
      let(:original_checksum) { ['invalid'] }

      it 'returns errors' do
        expect(service.verify).to include(match(/Unable to verify /))
      end
    end

    context 'when there is a checksum profile but no hyrax file' do
      before do
        allow(original_checksum).to receive(:first).and_raise StandardError
      end

      it 'reports the mismatch' do
        expect(service.verify).to include(match(/Unable to verify /))
      end
    end

    context 'when there were no checksums generated for the export' do
      before do
        allow(YAML).to receive(:load_file).and_raise(Errno::ENOENT)
      end

      it 'returns an error' do
        expect(service.verify).to include(match(/Unable to load /))
      end
    end

    context 'when the asset is a compound object' do
      before do
        allow(YAML).to receive(:load_file).and_raise(Errno::ENOENT)
        allow(migrated_work).to receive(:model_name).and_return('Generic')
      end

      it 'returns no errors' do
        expect(service.verify).to eq []
      end
    end
  end
end
