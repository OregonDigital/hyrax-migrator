# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyChecksumsService do
  let(:hyrax_work) { double }
  let(:service) { described_class.new(hyrax_work, profile_dir) }
  let(:profile_dir) { 'spec/fixtures/data' }
  let(:pid) { 'df70jh899' }
  let(:file_set) { instance_double('FileSet', id: 'bn999672v', uri: 'http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v') }
  let(:content_path) { 'spec/fixtures/data/world.png' }
  let(:original_file) { instance_double('hyrax_original_file', content: File.open(content_path).read) }

  before do
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(hyrax_work)
    allow(hyrax_work).to receive(:as_json).and_return(json)
    allow(hyrax_work).to receive(:file_sets).and_return([file_set])
    allow(file_set).to receive(:original_file).and_return(original_file)
    allow(hyrax_work).to receive(:id).and_return(pid)
  end

  describe 'verify_content' do
    let(:json) { {} }

    context 'when all checksums values match migrated content' do
      it 'returns no errors' do
        expect(service.verify_content).to eq([])
      end
    end

    context 'when checksums do not match with migrated content (invalid)' do
      let(:original_file) { instance_double('hyrax_original_file', content: 'invalid') }

      it 'returns errors' do
        expect(service.verify_content).to include(match(/Content does not match precomputed/))
      end
    end

    context 'when there were no checksums generated for the export' do
      before do
        allow(YAML).to receive(:load_file).and_raise(Errno::ENOENT)
      end

      it 'returns no errors' do
        expect(service.verify_content).to eq([])
      end
    end
  end
end
