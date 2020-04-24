# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::HyraxCore::DerivativePath do
  let(:hyrax_derivative_path) { described_class.new(file_set: file_set) }
  let(:file_set) do
    instance_double(
      'FileSet',
      id: 'bn999672v',
      uri: 'http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v',
      extracted_text: 'test',
      mime_type: 'image/png'
    )
  end

  let(:all_derivative_paths) { double }

  describe '#all_paths' do
    context 'when it raises an error' do
      before do
        allow(hyrax_derivative_path).to receive(:derivatives_for_reference).and_raise('error')
      end

      it { expect { hyrax_derivative_path.all_paths }.to raise_error('error') }
    end

    context 'when it succeeds' do
      before do
        allow(hyrax_derivative_path).to receive(:derivatives_for_reference).and_return(all_derivative_paths)
      end

      it { expect(hyrax_derivative_path.all_paths).to eq all_derivative_paths }
    end
  end
end
