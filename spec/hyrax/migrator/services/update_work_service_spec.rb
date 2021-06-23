# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::UpdateWorkService do
  let(:pid) { 'bobross' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:work) { create(:work, pid: pid, env: env) }
  let(:service) { described_class.new(work, config) }
  let(:env) { { attributes: attributes } }
  let(:attributes) { { title: 'Baby Pikachu' } }
  let(:actor_stack) { double }

  context 'when the work is successfully updated' do
    before do
      allow(service).to receive(:actor_stack).and_return(actor_stack)
      allow(actor_stack).to receive(:update).and_return(true)
    end

    it { expect(service.update_work).to eq true }
  end

  context 'when the work fails to update' do
    let(:error_message) { 'beep' }

    before do
      allow(service).to receive(:actor_stack).and_return(actor_stack)
      allow(actor_stack).to receive(:update).and_raise(error_message)
    end

    it { expect { service.update_work }.to raise_error StandardError, "failed to update work #{pid}, #{error_message}" }
  end

  ##
  # Don't mock the Hyrax dependencies, but allow it to fail naturally because the class is out of scope.
  context 'without upstream dependencies functional' do
    it { expect { service.update_work }.to raise_error StandardError, "failed to update work #{pid}, uninitialized constant Hyrax::CurationConcern" }
  end
end
