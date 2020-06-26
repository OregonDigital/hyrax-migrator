# frozen_string_literal:true

require 'nokogiri'
require 'hyrax/migrator/visibility_lookup'

RSpec.describe Hyrax::Migrator::VisibilityLookup do
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { described_class.new }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:pid) { '3t945r08v' }

  describe '#visibility_lookup' do
    context 'when there are access_restrictions' do
      before do
        allow(service).to receive(:access_restrictions).and_return([{ 'id' => 'http://opaquenamespace.org/ns/accessRestrictions/UOrestricted', '_destroy' => 0 }])
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

        it 'returns nil' do
          expect(service.lookup_visibility).to eq(nil)
        end
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
