# frozen_string_literal:true

require 'hyrax/migrator/visibility_lookup_preflight'

RSpec.describe Hyrax::Migrator::VisibilityLookupPreflight do
  let(:service) { described_class.new }

  describe '#visibility_lookup' do
    context 'when comparison_check returns true' do
      before do
        allow(service).to receive(:comparison_check).and_return(true)
        allow(service).to receive(:read_groups).and_return(['public'])
        allow(service).to receive(:access_restrictions).and_return([])
      end

      it 'returns no errors' do
        expect(service.lookup_visibility).to eq ''
      end
    end

    context 'when comparison_check returns false' do
      before do
        allow(service).to receive(:comparison_check).and_return(false)
        allow(service).to receive(:read_groups).and_return(['public'])
        allow(service).to receive(:access_restrictions).and_return(RDF::URI('http://iamrestricted.org'))
      end

      it 'returns an error message' do
        expect(service.lookup_visibility).to eq('read_groups does not agree with access_restrictions')
      end
    end
  end
end
