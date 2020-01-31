# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyMetadataService do
  describe 'verify_metadata' do
    let(:migrator_work) { double }
    let(:hyrax_work) { double }
    let(:config) { Hyrax::Migrator::Configuration.new }
    let(:service) { described_class.new(migrator_work, config, 'spec/fixtures/data') }
    let(:pid) { 'df70jh899' }
    let(:set) { double }
    let(:sets) { [set] }

    before do
      allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).and_return(hyrax_work)
      allow(hyrax_work).to receive(:as_json).and_return(json)
      allow(hyrax_work).to receive(:member_of_collections).and_return(sets)
      allow(migrator_work).to receive(:pid).and_return(pid)
      config.fields_map = 'spec/fixtures/fields_map.yml'
      allow(set).to receive(:id).and_return('joel-palmer')
      allow(hyrax_work).to receive(:admin_set_id).and_return('uo-scua')
    end

    context 'when all of the metadata is present' do
      let(:json) do
        hash = {}
        hash['id'] = pid
        hash['title'] = ['Letters']
        hash['identifier'] = ['AX057_b03_f01_011_012']
        hash['rights_statement'] = ['http://rightsstatements.org/vocab/NoC-US/1.0/']
        hash
      end

      it 'returns no errors' do
        expect(service.verify_metadata).to eq([])
      end
    end

    context 'when metadata is missing' do
      let(:json) do
        hash = {}
        hash['id'] = pid
        hash['title'] = ['Letters']
        hash['rights_statement'] = ['http://rightsstatements.org/vocab/NoC-US/1.0/']
        hash
      end

      it 'returns the error' do
        expect(service.verify_metadata).to eq(["Unable to verify identifier in #{pid}."])
      end
    end
  end
end
