# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Middleware do
  let(:middleware) { described_class }

  describe 'default' do
    let(:config) { Hyrax::Migrator::Middleware::Configuration.new }

    it 'returns the default middleware' do
      expect(middleware.default.actor_stack).to respond_to :crosswalk_metadata_initial
    end
  end

  describe 'custom' do
    let(:actor_stack) { [Hyrax::Migrator::Actors::ModelLookupActor] }
    let(:config) do
      c = Hyrax::Migrator::Middleware::Configuration.new
      c.actor_stack = actor_stack
      c
    end

    it 'returns middleware with a custom stack' do
      expect(middleware.custom(config).actor_stack).to respond_to :model_lookup_initial
    end
  end
end
