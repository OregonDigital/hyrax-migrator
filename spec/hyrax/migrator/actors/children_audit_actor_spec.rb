# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::ChildrenAuditActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid, file_path: File.join(Rails.root, '..', 'fixtures', pid)) }
  let(:pid) { '3t945r08v' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { double }
  let(:env) do
    { work_members_attributes: {
      '0' => { 'id' => 'abcde1234' },
      '1' => { 'id' => 'abcde1235' },
      '2' => { 'id' => 'abcde1236' }
    } }
  end

  before do
    allow(actor).to receive(:config).and_return(config)
    work.env = env
  end

  describe '#create' do
    context 'when the audit succeeds with children' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:audit).and_return(true)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('children_audit_succeeded')
      end

      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the audit succeeds with no children' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:audit).and_return(true)
        actor.next_actor = terminal
        work.env = {}
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('children_audit_succeeded')
      end

      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the audit fails' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:audit).and_return(2)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('children_audit_failed')
      end

      it 'records the number of children missing' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{pid}: 2 of 3 children are persisted.")
      end

      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
    end

    context 'when the audit errors' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:audit).and_raise(StandardError)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('children_audit_failed')
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
