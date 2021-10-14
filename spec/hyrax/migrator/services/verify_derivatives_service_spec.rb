# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyDerivativesService do
  let(:hyrax_work) { double }
  let(:migrated_work) { double }
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
  let(:service) { described_class.new(migrated_work) }
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
    allow(migrated_work).to receive(:asset).and_return(hyrax_work)
    allow(migrated_work).to receive(:original_profile).and_return(original_profile)
    allow(hyrax_work).to receive(:model_name).and_return('Thing')
    allow(Hyrax::Migrator::HyraxCore::DerivativePath).to receive(:new).with(anything).and_return(derivative_path)
    allow(hyrax_work).to receive(:as_json).and_return(json)
    allow(hyrax_work).to receive(:id).and_return('testabcd')
    allow(hyrax_work).to receive(:member_of_collections).and_return(sets)
    allow(hyrax_work).to receive(:file_sets).and_return([file_set])
    allow(file_set).to receive(:original_file).and_return(original_file)
    allow(set).to receive(:id).and_return('joel-palmer')
    allow(hyrax_work).to receive(:admin_set_id).and_return('uo-scua')
  end

  describe 'verify' do
    context 'when derivatives check is successful' do
      before do
        allow(service).to receive(:verify_file_set).and_return nil
      end

      it 'checks every file_set in hyrax_work (returns no errors)' do
        expect(service.verify).to eq []
      end
    end

    context 'when there is no file set' do
      before do
        allow(hyrax_work).to receive(:file_sets).and_return([])
      end

      context 'and the asset is an Image' do
        it 'returns a warning' do
          expect(service.verify).to eq(['warning: no file_sets found'])
        end
      end

      context 'and the asset is a Generic' do
        before do
          allow(hyrax_work).to receive(:model_name).and_return('Generic')
        end

        it 'returns no errors' do
          expect(service.verify).to eq([])
        end
      end
    end

    context 'when derivatives check fails due to error' do
      before do
        allow(service).to receive(:verify_file_set).and_raise(StandardError.new('I am an error'))
      end

      RSpec::Matchers.define :match_block do
        match do |response|
          response.call == ['I am an error']
        end
        supports_block_expectations
      end
      it 'raises error when hyrax fails' do
        expect { service.verify }.not_to raise_error
      end
      it 'returns the error message' do
        expect { service.verify }.to match_block
      end
    end
  end

  # Note that the verify method is responsible for creating the variable verification_errors.
  # Accordingly, the following methods need that variable initialized.

  describe 'check_pdf_derivatives' do
    let(:all_derivative_paths) { ['/data/tmp/shared/derivatives/c2/47/ds/08/x-jp2-0000.jp2', '/data/tmp/shared/derivatives/c2/47/ds/08/x-thumbnail.jpeg'] }
    let(:derivatives_info) do
      info = {}
      info['has_thumbnail'] = true
      info['page_count'] = 1
      info
    end

    it 'returns no errors' do
      service.instance_variable_set(:@verification_errors, [])
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
      service.instance_variable_set(:@verification_errors, [])
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
      service.instance_variable_set(:@verification_errors, [])
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
      service.instance_variable_set(:@verification_errors, [])
      service.check_audio_derivatives(file_set)
      expect(service.verification_errors).to eq([])
    end
  end

  describe 'check_video_derivatives' do
    let(:all_derivative_paths) { ['/data/tmp/shared/derivatives/nc/58/0m/64/9-jp2.jp2', '/data/tmp/shared/derivatives/nc/58/0m/64/9-mp4.mp4', '/data/tmp/shared/derivatives/nc/58/0m/64/9-webm.webm', '/data/tmp/shared/derivatives/nc/58/0m/64/9-thumbnail.jpeg'] }

    it 'returns the error' do
      service.instance_variable_set(:@verification_errors, [])
      service.check_video_derivatives(file_set)
      expect(service.verification_errors).to eq([])
    end
  end
end
