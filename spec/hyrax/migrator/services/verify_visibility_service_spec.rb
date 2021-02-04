# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyVisibilityService do
  let(:asset) { double }
  let(:original_profile) { YAML.load_file("spec/fixtures/data/#{pid}_profile.yml") }
  let(:pid) { 'df70jh899' }
  let(:service) { described_class.new(migrated_work) }
  let(:migrated_work) { double }

  before do
    allow(migrated_work).to receive(:asset).and_return(asset)
    allow(migrated_work).to receive(:original_profile).and_return(original_profile)
  end

  context 'when visibility of hyrax asset matches the profile' do
    before do
      allow(asset).to receive(:visibility).and_return('open')
    end

    it 'returns empty' do
      expect(service.verify).to eq('')
    end
  end

  context 'when visibility of hyrax asset does not match profile' do
    before do
      allow(asset).to receive(:visibility).and_return('uo')
    end

    it 'returns an error' do
      expect(service.verify).to eq('visibility error')
    end
  end
end
