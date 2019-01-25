# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::AbstractActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work) }

  it { expect(actor.config).to be_a Hyrax::Migrator::Configuration }
  it { expect(actor.next_actor).to be_nil }

  describe '#call_next_actor' do
    context 'when there is no next actor' do
      it { expect(actor.call_next_actor).to be_truthy }
    end

    context 'when work is set' do
      before do
        actor.next_actor = terminal
        actor.work = work
      end

      it 'calls create on next actor' do
        expect(actor.next_actor).to receive(:create).with(work)
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
