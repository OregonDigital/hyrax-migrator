# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Services::PersistWorkService do
  let(:pid) { 'bobross' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:work) { create(:work, pid: pid, env: env) }
  let(:service) { described_class.new(work, config) }
  let(:env) do
    {
      model: 'Image',
      attributes: attributes
    }
  end
  let(:attributes) do
    {
      depositor: 'bobross',
      title: ['title'],
      resource_type: ['http://purl.org/dc/dcmitype/Image'],
      rights_statement: ['http://rightstatements.org/vocab/InC/1.0/'],
      identifier: ['identifier']
    }
  end
  let(:actor_stack) { double }

  context 'when the works succeeds persisting' do
    before do
      allow(service).to receive(:actor_stack).and_return(actor_stack)
      allow(actor_stack).to receive(:create).and_return(true)
    end

    it { expect(service.persist_work).to eq true }
  end

  context 'when the work fails to persist' do
    let(:error_message) { 'boop' }

    before do
      allow(service).to receive(:actor_stack).and_return(actor_stack)
      allow(actor_stack).to receive(:create).and_raise(error_message)
    end

    it { expect { service.persist_work }.to raise_error StandardError, /#{error_message}/ }
  end

  ##
  # Don't mock the Hyrax dependencies, but allow it to fail naturally because the class is out of scope.
  context 'without upstream dependencies functional' do
    it { expect { service.persist_work }.to raise_error StandardError, /uninitialized constant Hyrax::CurationConcern/ }
  end
end
