# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::AbstractActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work) }
  let(:fake_user_record) { { email: 'admin@example.org' } }

  before do
    class User
      def self.where(_args)
        [{ email: 'admin@example.org' }]
      end
    end
  end

  it { expect(actor.config).to be_a Hyrax::Migrator::Configuration }
  it { expect(actor.next_actor).to be_nil }
  it { expect(actor.user).to eq fake_user_record }

  describe '#call_next_actor' do
    context 'when there is no next actor' do
      it { expect(actor.call_next_actor).to be_truthy }
    end

    context 'when work is set with create' do
      before do
        actor.next_actor = terminal
        actor.create(work)
      end

      it 'calls create on next actor' do
        expect(actor.next_actor).to receive(:create).with(work)
        actor.call_next_actor
      end
    end

    context 'when work is set with update' do
      before do
        actor.next_actor = terminal
        actor.update(work)
      end

      it 'calls update on next actor' do
        expect(actor.next_actor).to receive(:update).with(work)
        actor.call_next_actor
      end
    end

    context 'when work is not set' do
      before do
        actor.next_actor = terminal
      end

      it { expect { actor.call_next_actor }.to raise_error(StandardError, "#{described_class} missing @work, try calling super in #create or set the variable directly.") }
    end
  end
end
