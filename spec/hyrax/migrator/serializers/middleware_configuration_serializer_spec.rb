# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Serializers::MiddlewareConfigurationSerializer do
  let(:serializer) { described_class }
  let(:config) do
    c = Hyrax::Migrator::Middleware::Configuration.new
    c.actor_stack = [Hyrax::Migrator::Actors::BagValidatorActor]
    c
  end
  let(:hash) { { actor_stack: ['Hyrax::Migrator::Actors::BagValidatorActor'] } }

  describe 'serialize' do
    it 'delivers a array of strings' do
      expect(serializer.serialize(config)).to eq hash
    end
  end

  describe 'deserialize' do
    it 'delivers a configuration' do
      expect(serializer.deserialize(hash).actor_stack).to eq config.actor_stack
    end
  end
end
