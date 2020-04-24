# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyMetadataService do
  let(:migrator_work) { double }
  let(:hyrax_work) { double }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { described_class.new(migrator_work, config, 'spec/fixtures/data') }
  let(:pid) { 'df70jh899' }
  let(:set) { double }
  let(:sets) { [set] }
  let(:file_set) { instance_double('FileSet', id: 'bn999672v', uri: 'http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v', extracted_text: 'test', mime_type: 'image/png') }
  let(:content_path) { 'spec/fixtures/data/world.png' }
  let(:original_file) { instance_double('hyrax_original_file', content: File.open(content_path).read) }
  let(:derivative_path) { instance_double('Hyrax::Migrator::HyraxCore::DerivativePath', all_paths: []) }

  before do
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(hyrax_work)
    allow(Hyrax::Migrator::HyraxCore::DerivativePath).to receive(:new).with(anything).and_return(derivative_path)
    allow(hyrax_work).to receive(:as_json).and_return(json)
    allow(hyrax_work).to receive(:member_of_collections).and_return(sets)
    allow(hyrax_work).to receive(:file_sets).and_return([file_set])
    allow(file_set).to receive(:original_file).and_return(original_file)
    allow(migrator_work).to receive(:pid).and_return(pid)
    config.fields_map = 'spec/fixtures/fields_map.yml'
    allow(set).to receive(:id).and_return('joel-palmer')
    allow(hyrax_work).to receive(:admin_set_id).and_return('uo-scua')
  end

  describe 'verify_metadata' do
    context 'when all of the metadata is present' do
      let(:json) do
        hash = {}
        hash['id'] = pid
        hash['title'] = ['Letters']
        hash['identifier'] = ['AX057_b03_f01_011_012']
        hash['rights_statement'] = ['http://rightsstatements.org/vocab/NoC-US/1.0/']
        hash
      end

      it 'returns no errors' do
        expect(service.verify_metadata).to eq([])
      end
    end

    context 'when metadata is missing' do
      let(:json) do
        hash = {}
        hash['id'] = pid
        hash['title'] = ['Letters']
        hash['rights_statement'] = ['http://rightsstatements.org/vocab/NoC-US/1.0/']
        hash
      end

      it 'returns the error' do
        expect(service.verify_metadata).to eq(["Unable to verify identifier in #{pid}."])
      end
    end
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
  end

  describe 'verify_derivatives' do
    let(:json) { {} }
    let(:derivatives_service) { instance_double('Hyrax::Migrator::Services::VerifyDerivativesService', verify: []) }

    before do
      allow(service).to receive(:derivatives_service).and_return(derivatives_service)
    end

    context 'when derivatives exist' do
      it 'returns no errors' do
        expect(service.verify_derivatives).to eq([])
      end
    end

    context 'when missing derivatives' do
      let(:derivatives_service) { instance_double('Hyrax::Migrator::Services::VerifyDerivativesService', verify: ['Missing thumbnail derivative']) }

      it 'returns errors' do
        expect(service.verify_derivatives).to include(match(/Missing/))
      end
    end
  end
end
