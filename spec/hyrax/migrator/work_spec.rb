# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Work do
  let(:model) { create(:work) }

  it { expect(model.env).to be_a Hash }
end
