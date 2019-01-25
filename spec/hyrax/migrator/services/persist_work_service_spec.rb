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

  context 'when the work fails to persist' do
    let(:model) { double }
    let(:error_message) { 'boop' }

    before do
      allow(service).to receive(:model).and_return(model)
      allow(model).to receive(:attributes=)
      allow(model).to receive(:save).and_raise(error_message)
    end

    it { expect { service.persist_work }.to raise_error StandardError, "failed persisting work #{pid}, #{error_message}" }
  end
end
