# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Middleware::DefaultMiddleware do
  subject { middleware }

  let(:middleware) { described_class.new(actors) }
  let(:actors) { [] }

  it { is_expected.to respond_to(:actor_stack) }
  it { expect(middleware.actor_stack).to eq nil }
  it { is_expected.to respond_to(:start) }

  context 'with an array of actors' do
    let(:actors) { [TestActor, TestActor, AnotherTestActor] }
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
      let(:aasm_state) { 'another_test_failed' }

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
    next_actor_for(work)
  end
end

class AnotherTestActor < Hyrax::Migrator::Actors::AbstractActor
  aasm do
    state :another_test_init, initial: true
    state :another_test_failed
    state :another_test_succeeded
    event :another_test_succeeded do
      transitions from: :another_test_init, to: :another_test_succeeded
    end
  end
  def create(work)
    next_actor_for(work)
  end
end
