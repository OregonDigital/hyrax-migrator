# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::UpdateWorkActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid) }
  let(:pid) { '3t945r08v' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { double }

  before do
    allow(actor).to receive(:config).and_return(config)
  end

  describe '#update' do
    context 'when the service succeeds' do
      before do
        work.env[:attributes] = { title: 'Baby Pikachu' }
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:update_work).and_return(true)
        actor.next_actor = terminal
      end

      it 'sets the proper state' do
        actor.update(work)
        expect(work.aasm_state).to eq('update_work_succeeded')
      end

      it 'sets the status message' do
        actor.update(work)
        expect(work.status_message).to eq("Work #{work.pid} updated.")
      end

      it 'sets the status' do
        actor.update(work)
        expect(work.status).to eq('success')
      end

      it 'calls the next actor' do
        expect(terminal).to receive(:update)
        actor.update(work)
      end
    end

    context 'when the service fails' do
      before do
        work.env[:attributes] = { title: 'Baby Pikachu' }
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:update_work).and_return(false)
        actor.next_actor = terminal
      end

      it 'sets the proper state' do
        actor.update(work)
        expect(work.aasm_state).to eq('update_work_failed')
      end

      it 'sets the status message' do
        actor.update(work)
        expect(work.status_message).to eq("Work #{work.pid} failed updating.")
      end

      it 'sets the status' do
        actor.update(work)
        expect(work.status).to eq('fail')
      end

      it 'does not call the next actor' do
        expect(terminal).not_to receive(:update)
        actor.update(work)
      end
    end

    context 'when the service raises an exception' do
      before do
        work.env[:attributes] = { title: 'Baby Pikachu' }
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:update_work).and_raise(StandardError)
        actor.next_actor = terminal
      end

      it 'sets the proper state' do
        actor.update(work)
        expect(work.aasm_state).to eq('update_work_failed')
      end

      it 'sets the status message' do
        actor.update(work)
        expect(work.status_message).to eq("Work #{work.pid} failed updating.")
      end

      it 'sets the status' do
        actor.update(work)
        expect(work.status).to eq('fail')
      end

      it 'does not call the next actor' do
        expect(terminal).not_to receive(:update)
        actor.update(work)
      end

      it 'logs the failure' do
        expect(Rails.logger).to receive(:warn)
        actor.update(work)
      end
    end
  end
end
