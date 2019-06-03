# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::LoadFileIdentityService do
  let(:pid) { '3t945r08v' }
  let(:work_file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:service) { described_class.new(work_file_path) }

  describe '#content_file_checksums' do
    context 'when there are default manifest files' do
      let(:expected_md5_data) do
        {
          file_name: '3t945r08v_content.jpeg',
          checksum: 'cd36b025f4393ace2caa47c6e65f25ed',
          checksum_encoding: 'md5'
        }
      end
      let(:expected_sha1_data) do
        {
          file_name: '3t945r08v_content.jpeg',
          checksum: 'c1249a0e4d7c8cf64f5de6892681287e34a87b10',
          checksum_encoding: 'sha1'
        }
      end

      it 'returns the an array of two hashes for default encoding' do
        expect(service.content_file_checksums).to include(expected_sha1_data, expected_md5_data)
      end
    end

    context 'when work_file_path (bag directory) does not exist' do
      let(:error) { StandardError }
      let(:work_file_path) { 'unknown-path' }

      it 'raises an error' do
        expect { service.content_file_checksums }.to raise_error(error)
      end
    end

    context 'when it cant find manifest files for given bag' do
      let(:error) { StandardError }

      before do
        allow(File).to receive(:basename).with(anything).and_return('invalid-format-manifest-file.txt')
      end

      it 'raises an error' do
        expect { service.content_file_checksums }.to raise_error(error)
      end
    end
  end
end
