# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::VisibilityLookupService do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { described_class.new(work, config) }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:pid) { '3t945r08v' }

  describe '#visibility_lookup' do
    context 'with a missing xml file in the bag manifest' do
      before do
        stub_const('Hyrax::Migrator::Services::VisibilityLookupService::XML_FILE', 'bogus_file.xml')
      end

      it { expect { service.lookup_visibility }.to raise_error(StandardError, "could not find an xml file ending with '#{described_class::XML_FILE}' in #{work.file_path}/data") }
    end

    context 'with a missing xml file in the directory' do
      before do
        allow(service).to receive(:xml_file).and_return('mocking_a_bogus_file_in_manifest.xml')
      end

      it { expect { service.lookup_visibility }.to raise_error StandardError, "could not find xml file mocking_a_bogus_file_in_manifest.xml in #{work.file_path}/data" }
    end

    context 'with an invalid data directory' do
      let(:file_path) { 'bogus/path' }

      it { expect { service.lookup_visibility }.to raise_error StandardError, "data directory #{work.file_path}/data not found" }
    end

    context 'with an invalid xml node xpath' do
      before do
        stub_const('Hyrax::Migrator::Services::VisibilityLookupService::XML_NODE', '//bob/ross/GOAT')
      end

      it { expect { service.lookup_visibility }.to raise_error(StandardError, "could not find #{described_class::XML_NODE} in xml file") }
    end
  end
end
