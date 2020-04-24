# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyDerivativesService do
  let(:hyrax_work) { double }
  let(:original_profile) { YAML.load_file(File.join('spec/fixtures/data', "#{pid}_profile.yml")) }
  let(:service) { described_class.new(hyrax_work, original_profile) }
  let(:pid) { 'df70jh899' }
  let(:set) { double }
  let(:sets) { [set] }
  let(:file_set) do
    instance_double(
      'FileSet',
      id: 'bn999672v',
      uri: 'http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v',
      extracted_text: 'test',
      mime_type: 'image/png'
    )
  end
  let(:content_path) { 'spec/fixtures/data/world.png' }
  let(:original_file) { instance_double('hyrax_original_file', content: File.open(content_path).read) }
  let(:all_derivative_paths) { [] }
  let(:derivative_path) { instance_double('Hyrax::Migrator::HyraxCore::DerivativePath', all_paths: all_derivative_paths) }
  let(:json) do
    hash = {}
    hash['id'] = pid
    hash['title'] = ['Letters']
    hash['identifier'] = ['AX057_b03_f01_011_012']
    hash['rights_statement'] = ['http://rightsstatements.org/vocab/NoC-US/1.0/']
    hash
  end

  before do
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(hyrax_work)
    allow(Hyrax::Migrator::HyraxCore::DerivativePath).to receive(:new).with(anything).and_return(derivative_path)
    allow(hyrax_work).to receive(:as_json).and_return(json)
    allow(hyrax_work).to receive(:id).and_return('testabcd')
    allow(hyrax_work).to receive(:member_of_collections).and_return(sets)
    allow(hyrax_work).to receive(:file_sets).and_return([file_set])
    allow(file_set).to receive(:original_file).and_return(original_file)
    allow(set).to receive(:id).and_return('joel-palmer')
    allow(hyrax_work).to receive(:admin_set_id).and_return('uo-scua')
  end

  describe 'check_pdf_derivatives' do
    let(:all_derivative_paths) { [] }

    it 'returns no errors' do
      expect(service.check_pdf_derivatives(file_set)).to eq([])
    end
  end

  describe 'check_image_derivatives' do
    let(:all_derivative_paths) { [] }

    it 'returns the error' do
      expect(service.check_image_derivatives(file_set)).to eq([])
    end
  end

  describe 'check_office_document_derivatives' do
    let(:all_derivative_paths) { [] }

    it 'returns the error' do
      expect(service.check_office_document_derivatives(file_set)).to eq([])
    end
  end

  describe 'check_audio_derivatives' do
    let(:all_derivative_paths) { [] }

    it 'returns the error' do
      expect(service.check_audio_derivatives(file_set)).to eq([])
    end
  end

  describe 'check_video_derivatives' do
    let(:all_derivative_paths) { [] }

    it 'returns the error' do
      expect(service.check_video_derivatives(file_set)).to eq([])
    end
  end
end
