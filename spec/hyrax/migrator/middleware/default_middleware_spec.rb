# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Middleware::DefaultMiddleware do
  subject { middleware }

  let(:middleware) { described_class.new(actors) }
  let(:actors) { [] }

  it { is_expected.to respond_to(:actor_stack) }
  it { expect(middleware.actor_stack).to eq nil }
  it { is_expected.to respond_to(:start) }

  context 'with an array of actors' do
    let(:actors) { [TestActor, TestActor, TerminalTestActor] }
    let(:aasm_state) { nil }
    let(:work) { create(:work, aasm_state: aasm_state) }

    describe '#start with a work having no previously set aasm_state' do
      it 'calls the first actor' do
        expect(middleware.actor_stack).to receive(:create).with(work)
        middleware.start(work)
      end
      it 'calls the second actor' do
        expect(middleware.actor_stack.next_actor).to receive(:create).with(work)
        middleware.start(work)
      end
      it 'calls the last actor' do
        expect(middleware.actor_stack.next_actor.next_actor).to receive(:create).with(work)
        middleware.start(work)
      end
    end

    describe '#start with a work having a previously set aasm_state' do
      let(:aasm_state) { 'terminal_test_failed' }

      it 'skips the first actor' do
        expect(middleware.actor_stack).not_to receive(:create)
        middleware.start(work)
      end
      it 'skips the second actor' do
        expect(middleware.actor_stack.next_actor).not_to receive(:create)
        middleware.start(work)
      end
      it 'calls the actor with the aasm_state method' do
        expect(middleware.actor_stack.next_actor.next_actor).to receive(:create).with(work)
        middleware.start(work)
      end
    end

    describe '#start with an improperly overridden #create in an Actor' do
      let(:actors) { [TerminalTestActor, TestActor] }
      let(:aasm_state) { 'terminal_test_failed' }

      it 'raises an exception because @work was not set' do
        expect { middleware.start(work) }.to raise_error StandardError
      end
    end
  end
end

class TestActor < Hyrax::Migrator::Actors::AbstractActor
  aasm do
    state :test_init, initial: true
    state :test_failed
    state :test_succeeded
    event :test_succeeded do
      transitions from: :test_init, to: :test_succeeded
    end
  end
  def create(work)
    super
    call_next_actor
  end
end

class TerminalTestActor < Hyrax::Migrator::Actors::AbstractActor
  aasm do
    state :terminal_test_init, initial: true
    state :terminal_test_failed
    state :terminal_test_succeeded
    event :terminal_test_succeeded do
      transitions from: :terminal_test_init, to: :terminal_test_succeeded
    end
  end
  def create(_work)
    # Super not called, expects actor to fail in call_next_actor
    # super
    call_next_actor
  end
end
