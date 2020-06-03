# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::RequiredFieldsActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid) }
  let(:pid) { '3t945r08v' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { double }
  let(:env) { { errors: [] } }

  before do
    allow(actor).to receive(:config).and_return(config)
    work.env = env
  end

  describe '#create' do
    context 'when the service verifies successfully' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:verify_fields).and_return([])
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('required_fields_succeeded')
      end

      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the verify fails' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:verify_fields).and_return(['missing required field: title'])
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('required_fields_failed')
      end

      it 'records the fields missing' do
        actor.create(work)
        expect(work.env[:errors]).to include('missing required field: title')
      end

      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
    end

    context 'when the service errors' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:verify_fields).and_raise(StandardError)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('required_fields_failed')
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
