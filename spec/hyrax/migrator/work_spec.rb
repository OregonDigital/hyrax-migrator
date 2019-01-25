# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Work do
  let(:model) { create(:work) }

  it { expect(model.env).to be_a Hash }
  it { expect(described_class::SUCCESS).to eq('success') }
  it { expect(described_class::FAIL).to eq('fail') }
end
