# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::ModelLookupService do
  let(:crosswalk_yaml_path) { File.join(Rails.root, '..', 'fixtures', 'model_lookup.yml') }
  let(:service) { described_class.new(work, crosswalk_yaml_path) }
  let(:work) { create(:work, pid: pid, file_path: File.join(Rails.root, '..', 'fixtures', pid)) }
  let(:pid) { '3t945r08v' }
  let(:object) { RDF::URI('http://purl.org/dc/dcmitype/Image') }

  it { expect(service.model).to eq 'Image' }

  context 'with a missing lookup configuration' do
    let(:crosswalk_yaml_path) { File.join(Rails.root, '..', 'fixtures', 'doesntexist.yml') }
    let(:service) { described_class }

    it { expect { service.new(work, crosswalk_yaml_path) }.to raise_error StandardError }
  end

  describe '#model' do
    context 'with a missing metadata file in the bag manifest' do
      before do
        stub_const('Hyrax::Migrator::Services::ModelLookupService::METADATA_FILE', 'bogus_metadata_file.nt')
      end

      it { expect { service.model }.to raise_error(StandardError, "could not find a metadata file ending with '#{described_class::METADATA_FILE}' in #{work.bag.data_dir}") }
    end

    context 'with a missing metadata file in the directory' do
      before do
        allow(service).to receive(:metadata_file).and_return('mocking_a_bogus_file_in_manifest.nt')
      end

      it { expect { service.model }.to raise_error StandardError, 'could not find metadata file at mocking_a_bogus_file_in_manifest.nt' }
    end

    context 'with an invalid type uri' do
      before do
        stub_const('Hyrax::Migrator::Services::ModelLookupService::TYPE_URI', 'Bob_Ross_GOAT')
      end

      it { expect { service.model }.to raise_error(StandardError, "could not find #{described_class::TYPE_URI} in metadata") }
    end

    context 'with an invalid metadata format' do
      before do
        stub_const('Hyrax::Migrator::Services::ModelLookupService::METADATA_FORMAT', :turtle)
      end

      it { expect { service.model }.to raise_error(StandardError, "invalid metadata format, could not load #{described_class::METADATA_FORMAT} metadata file") }
    end

    context 'when missing a configuration for the type uri' do
      before do
        allow(service).to receive(:crosswalk).and_return('http://doesntexist' => 'Image')
      end

      it { expect { service.model }.to raise_error(StandardError, "could not find a configuration for #{object} in #{crosswalk_yaml_path}") }
    end
  end
end
