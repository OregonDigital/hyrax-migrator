# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::BatchesController, type: :controller do
  routes { Hyrax::Migrator::Engine.routes }
  let(:service) { instance_double('BagFileLocationService', bags_to_ingest: locations) }
  let(:locations) do
    hash = ActiveSupport::HashWithIndifferentAccess.new
    hash['kawaii'] = ["#{path}abcde1234", "#{path}fghij5678"]
    hash
  end
  let(:path) { 'fruit_bowl/banana/' }

  describe 'show' do
    before do
      allow(Hyrax::Migrator::Services::BagFileLocationService).to receive(:new).and_return(service)
      get :show, params: { id: 'kawaii' }
    end

    it 'shows' do
      expect(response).to be_success
    end
  end
end
