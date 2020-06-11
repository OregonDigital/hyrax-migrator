# frozen_string_literal:true

require 'nokogiri'

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

    context 'when there are access_restrictions' do
      before do
        work[:env][:attributes][:access_restrictions_attributes] = [{ 'id' => 'http://opaquenamespace.org/ns/accessRestrictions/UOrestricted', '_destroy' => 0 }]
      end

      context 'when groups are not public' do
        let(:groups) { %w[admin archivist University-of-Oregon] }

        before do
          allow(service).to receive(:read_groups).and_return groups
        end

        it 'returns the result' do
          expect(service.lookup_visibility).to eq(visibility: 'authenticated')
        end
      end

      context 'when groups are public' do
        let(:groups) { %w[public admin archivist] }

        before do
          allow(service).to receive(:read_groups).and_return groups
        end

        it 'raises an error' do
          service.lookup_visibility
        rescue StandardError => e
          expect(e.message).to eq('visibility does not agree with access_restrictions')
        end
      end
    end
  end

  describe '#read_groups' do
    context 'when the file is valid' do
      let(:xml) { '<rightsMetadata><access type=\'read\'><group>public</group></access></rightsMetadata>' }
      let(:nodes) { Nokogiri::XML(xml).search('group') }
      let(:doc) { instance_double(Nokogiri::XML::Document) }

      before do
        allow(service).to receive(:doc).and_return(doc)
        allow(doc).to receive(:search).and_return(nodes)
      end

      it 'extracts the groups' do
        expect(service.send(:read_groups)).to eq(%w[public])
      end
    end
  end

  describe '#lookup' do
    context 'when the original group is public' do
      let(:groups) { %w[public admin archivist] }

      it 'returns open' do
        expect(service.send(:lookup, groups)).to eq(visibility: 'open')
      end
    end

    context 'when the original group is an institution' do
      let(:groups) { %w[admin archivist University-of-Oregon] }

      it 'returns authenticated' do
        expect(service.send(:lookup, groups)).to eq(visibility: 'authenticated')
      end
    end

    context 'when the original group is none of the above' do
      let(:groups) { %w[admin archivist] }

      it 'returns restricted' do
        expect(service.send(:lookup, groups)).to eq(visibility: 'restricted')
      end
    end
  end

  describe '#comparison_check' do
    context 'when there are no access_restrictions' do
      let(:visibility) { { visibility: 'open' } }

      it 'returns true' do
        expect(service.send(:comparison_check, visibility)).to eq true
      end
    end
  end
end
