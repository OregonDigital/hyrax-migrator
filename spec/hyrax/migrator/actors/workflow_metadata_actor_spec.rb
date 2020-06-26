# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::WorkflowMetadataActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid) }
  let(:pid) { 'fx719n867' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { double }

  before do
    allow(actor).to receive(:config).and_return(config)
  end

  describe '#create' do
    context 'when the service succeeds' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:workflow_profile).and_return(double)
        allow(service).to receive(:update_asset).and_return(true)
        actor.next_actor = terminal
      end

      it 'sets the proper state' do
        actor.create(work)
        expect(work.aasm_state).to eq('workflow_metadata_succeeded')
      end

      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} retrieved metadata from workflowMetadata profile.")
      end

      it 'sets the status' do
        actor.create(work)
        expect(work.status).to eq('success')
      end

      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the service fails' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:workflow_profile).and_return(nil)
        allow(service).to receive(:update_asset).and_return(false)
        actor.next_actor = terminal
      end

      it 'sets the proper state' do
        actor.create(work)
        expect(work.aasm_state).to eq('workflow_metadata_failed')
      end

      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} failed while retrieving workflowMetadata profile.")
      end

      it 'sets the status' do
        actor.create(work)
        expect(work.status).to eq('fail')
      end

      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
    end

    context 'when the service raises an exception' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:workflow_profile).and_raise(StandardError)
        allow(service).to receive(:update_asset).and_return(false)
        actor.next_actor = terminal
      end

      it 'sets the proper state' do
        actor.create(work)
        expect(work.aasm_state).to eq('workflow_metadata_failed')
      end

      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} failed while retrieving workflowMetadata profile.")
      end

      it 'sets the status' do
        actor.create(work)
        expect(work.status).to eq('fail')
      end

      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end

      it 'logs the failure' do
        expect(Rails.logger).to receive(:warn)
        actor.create(work)
      end
    end
  end
end
