# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::HyraxCore::ActorStack do
  let(:actor_stack) { described_class.new(migration_user: migration_user, model: model, attributes: attributes) }
  let(:migration_user) { 'admin@example.org' }
  let(:model) { 'String' }
  let(:attributes) { { title: ['Title'] } }
  let(:actor_environment) { double }
  let(:actor) { double }

  describe '#create' do
    before do
      allow(actor_stack).to receive(:actor_environment).and_return(actor_environment)
      allow(actor_stack).to receive(:actor).and_return(actor)
    end

    context 'when it raises an error' do
      before do
        allow(actor).to receive(:create).and_raise('boom')
      end

      it { expect { actor_stack.create }.to raise_error('boom') }
    end

    context 'when it succeeds' do
      before do
        allow(actor).to receive(:create).and_return(true)
      end

      it { expect(actor_stack.create).to eq true }
    end

    context 'when it fails' do
      before do
        allow(actor).to receive(:create).and_return(false)
      end

      it { expect(actor_stack.create).to eq false }
    end
  end

  describe '#update' do
    before do
      allow(actor_stack).to receive(:actor_environment).and_return(actor_environment)
      allow(actor_stack).to receive(:actor).and_return(actor)
    end

    context 'when it raises an error' do
      before do
        allow(actor).to receive(:update).and_raise('boom')
      end

      it { expect { actor_stack.update }.to raise_error('boom') }
    end

    context 'when it succeeds' do
      before do
        allow(actor).to receive(:update).and_return(true)
      end

      it { expect(actor_stack.update).to eq true }
    end

    context 'when it fails' do
      before do
        allow(actor).to receive(:update).and_return(false)
      end

      it { expect(actor_stack.update).to eq false }
    end
  end
end
