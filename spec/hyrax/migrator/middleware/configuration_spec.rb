# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Middleware::Configuration do
  subject { object }

  let(:object) { described_class.new }

  it { is_expected.to respond_to(:actor_stack) }
  it { expect(object.actor_stack).to eq [] }
end
