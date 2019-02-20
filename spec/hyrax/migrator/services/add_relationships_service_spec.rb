# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::AddRelationshipsService do
  let(:pid) { 'bobross' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:work) { create(:work, pid: pid, env: env) }
  let(:service) { described_class.new(work, config) }
  let(:env) do
    {
      attributes: attributes
    }
  end
  let(:attributes) do
    {
      depositor: 'bobross',
      work_members_attributes: { '0' => { 'id' => 'abcde1234' },
                                 '1' => { 'id' => 'abcde1235' } }
    }
  end
  let(:actor_stack) { double }

  context 'when the relationships are successfully added' do
    before do
      allow(service).to receive(:actor_stack).and_return(actor_stack)
      allow(actor_stack).to receive(:update).and_return(true)
    end

    it { expect(service.add_relationships).to eq true }
  end

  context 'when the work fails to add relationships' do
    let(:error_message) { 'beep' }

    before do
      allow(service).to receive(:actor_stack).and_return(actor_stack)
      allow(actor_stack).to receive(:update).and_raise(error_message)
    end

    it { expect { service.add_relationships }.to raise_error StandardError, "failed to add relationships work #{pid}, #{error_message}" }
  end

  ##
  # Don't mock the Hyrax dependencies, but allow it to fail naturally because the class is out of scope.
  context 'without upstream dependencies functional' do
    it { expect { service.add_relationships }.to raise_error StandardError, "failed to add relationships work #{pid}, uninitialized constant Hyrax::CurationConcern" }
  end
end
