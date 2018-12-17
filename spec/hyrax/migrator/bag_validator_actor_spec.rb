# frozen_string_literal: true

require 'bagit'

RSpec.describe Hyrax::Migrator::Actors::BagValidatorActor do
  let(:actor) { described_class.new(terminal) }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, aasm_state: nil) }
  let(:bag) { BagIt::Bag.new('00001') }

  describe '#create' do
    context 'when the validation succeeds' do
      before do
        allow(BagIt::Bag).to receive(:new).and_return(bag)
        allow(bag).to receive(:valid?).and_return(true)
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('bag_validator_succeeded')
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the validation fails' do
      before do
        allow(BagIt::Bag).to receive(:new).and_return(bag)
        allow(bag).to receive(:valid?).and_return(false)
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('bag_validator_failed')
      end
      it 'does not call the next actor' do
        expect(terminal).not_to receive('create')
        actor.create(work)
      end
    end

    context 'when the process blows up' do
      let(:error) { StandardError.new('my-error') }

      before do
        allow(BagIt::Bag).to receive(:new).and_raise(error)
      end

      it 'logs the failure' do
        expect(Rails.logger).to receive(:warn)
        actor.create(work)
      end
    end
  end
end
