# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyDerivativesService do
  let(:hyrax_work) { double }
  let(:derivatives_info) do
    info = {}
    info['has_thumbnail'] = false
    info['has_content_ocr'] = false
    info['page_count'] = 10
    info['has_content_ogg'] = true
    info['has_content_mp3'] = true
    info['has_medium_image'] = false
    info['has_pyramidal_image'] = false
    info['has_content_mp4'] = false
    info['has_content_jpg'] = false
    info
  end
  let(:original_profile) do
    hash = {}
    hash['derivatives_info'] = derivatives_info
    hash
  end
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
    let(:all_derivative_paths) { ['/data/tmp/shared/derivatives/c2/47/ds/08/x-jp2-0000.jp2', '/data/tmp/shared/derivatives/c2/47/ds/08/x-thumbnail.jpeg'] }
    let(:derivatives_info) do
      info = {}
      info['has_thumbnail'] = true
      info['page_count'] = 1
      info
    end

    it 'returns no errors' do
      service.check_pdf_derivatives(file_set)
      expect(service.verification_errors).to eq([])
    end
  end

  describe 'check_image_derivatives' do
    let(:all_derivative_paths) { ['/data/tmp/shared/derivatives/p8/41/8n/20/k-jp2.jp2', '/data/tmp/shared/derivatives/p8/41/8n/20/k-thumbnail.jpeg'] }
    let(:derivatives_info) do
      info = {}
      info['has_thumbnail'] = true
      info
    end

    it 'returns the error' do
      service.check_image_derivatives(file_set)
      expect(service.verification_errors).to eq([])
    end
  end

  describe 'check_office_document_derivatives' do
    let(:all_derivative_paths) { ['/data/tmp/shared/derivatives/nv/93/52/84/1-jp2-0000.jp2', '/data/tmp/shared/derivatives/nv/93/52/84/1-thumbnail.jpeg'] }
    let(:derivatives_info) do
      info = {}
      info['has_thumbnail'] = true
      info['page_count'] = 1
      info
    end

    it 'returns the error' do
      service.check_office_document_derivatives(file_set)
      expect(service.verification_errors).to eq([])
    end
  end

  describe 'check_audio_derivatives' do
    let(:all_derivative_paths) { ['/data/tmp/shared/derivatives/cn/69/m4/12/8-ogg.ogg', '/data/tmp/shared/derivatives/cn/69/m4/12/8-jp2.jp2', '/data/tmp/shared/derivatives/cn/69/m4/12/8-mp3.mp3', '/data/tmp/shared/derivatives/cn/69/m4/12/8-thumbnail.jpeg'] }
    let(:derivatives_info) do
      info = {}
      info['has_thumbnail'] = true
      info
    end

    it 'returns the error' do
      service.check_audio_derivatives(file_set)
      expect(service.verification_errors).to eq([])
    end
  end

  describe 'check_video_derivatives' do
    let(:all_derivative_paths) { ['/data/tmp/shared/derivatives/nc/58/0m/64/9-jp2.jp2', '/data/tmp/shared/derivatives/nc/58/0m/64/9-mp4.mp4', '/data/tmp/shared/derivatives/nc/58/0m/64/9-webm.webm', '/data/tmp/shared/derivatives/nc/58/0m/64/9-thumbnail.jpeg'] }

    it 'returns the error' do
      service.check_video_derivatives(file_set)
      expect(service.verification_errors).to eq([])
    end
  end
end
