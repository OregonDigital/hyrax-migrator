# frozen_string_literal: true

require 'rdf'

RSpec.describe Hyrax::Migrator::Actors::AdminSetMembershipActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid) }
  let(:pid) { 'abcde1234' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:result_hash) { { admin_set_id: 'default/admin' } }
  let(:asms) { instance_double('Hyrax::Migrator::Services::AdminSetMembershipService') }

  describe '#create' do
    context 'when the hash is successfully created' do
      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::AdminSetMembershipService).to receive(:new).and_return(asms)
        allow(asms).to receive(:acquire_set_ids).and_return(result_hash)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('admin_set_membership_succeeded')
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when admin_set_membership_service fails' do
      let(:error) { StandardError }

      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::AdminSetMembershipService).to receive(:new).and_return(asms)
        allow(asms).to receive(:acquire_set_ids).and_raise(error)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('admin_set_membership_failed')
      end
      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
    end
  end
end
