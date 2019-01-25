# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::ModelLookupService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:model_crosswalk) { File.join(Rails.root, '..', 'fixtures', 'model_crosswalk.yml') }
  let(:registered_model) { 'Image' }
  let(:service) { described_class.new(work, config) }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:pid) { '3t945r08v' }
  let(:node_value) { 'info:fedora/afmodel:Image' }

  before do
    config.model_crosswalk = model_crosswalk
    config.register_model registered_model
  end

  it { expect(service.model).to eq 'Image' }

  context 'with a missing lookup configuration' do
    let(:model_crosswalk) { File.join(Rails.root, '..', 'fixtures', 'doesntexist.yml') }
    let(:service) { described_class }

    it { expect { service.new(work, config) }.to raise_error StandardError }
  end

  describe '#model' do
    context 'with a missing xml file in the bag manifest' do
      before do
        stub_const('Hyrax::Migrator::Services::ModelLookupService::XML_FILE', 'bogus_file.xml')
      end

      it { expect { service.model }.to raise_error(StandardError, "could not find an xml file ending with '#{described_class::XML_FILE}' in #{work.file_path}/data") }
    end

    context 'with a missing xml file in the directory' do
      before do
        allow(service).to receive(:xml_file).and_return('mocking_a_bogus_file_in_manifest.xml')
      end

      it { expect { service.model }.to raise_error StandardError, "could not find xml file mocking_a_bogus_file_in_manifest.xml in #{work.file_path}/data" }
    end

    context 'with an invalid data directory' do
      let(:file_path) { 'bogus/path' }

      it { expect { service.model }.to raise_error StandardError, "data directory #{work.file_path}/data not found" }
    end

    context 'with an invalid xml node xpath' do
      before do
        stub_const('Hyrax::Migrator::Services::ModelLookupService::XML_NODE_XPATH', '//bob/ross/GOAT')
      end

      it { expect { service.model }.to raise_error(StandardError, "could not find #{described_class::XML_NODE_XPATH} in xml file") }
    end

    context 'when missing a configuration a registered model' do
      let(:registered_model) { 'BobRoss' }

      it { expect { service.model }.to raise_error(StandardError, 'Image not a registered model in the migrator initializer') }
    end
  end
end
