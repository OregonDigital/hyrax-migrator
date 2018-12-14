# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Middleware::DefaultMiddleware do
  subject { object }

  let(:object) { described_class.new(actors) }
  let(:actors) { [] }

  it { is_expected.to respond_to(:actor_stack) }
  it { expect(object.actor_stack).to eq [] }
  it { is_expected.to respond_to(:start) }

  context 'with an array of actors' do
    let(:actors) { [TestActor, TestActor] }

    it { expect(object.actor_stack.count).to eq 2 }

    describe '#start' do

    end
  end
end

class TestActor < Hyrax::Migrator::Actors::AbstractActor

  aasm do
    state :test_init, initial: true
    state :test_failed
    state :test_succeeded
    event :succeeded do
      transitions from: :test_init, to: :test_succeeded
    end
  end
  def create(env); end
end
