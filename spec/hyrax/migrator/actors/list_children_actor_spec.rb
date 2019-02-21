# frozen_string_literal: true

require 'rdf'

RSpec.describe Hyrax::Migrator::Actors::ListChildrenActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid) }
  let(:pid) { 'abcde1234' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:result_hash) { { id: 'I am what I am' } }
  let(:lcs) { instance_double('Hyrax::Migrator::Services::ListChildrenService') }

  describe '#create' do
    context 'when the hash is successfully created' do
      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
        allow(lcs).to receive(:list_children).and_return(result_hash)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('list_children_succeeded')
      end
      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} Children added.")
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
      it 'adds to work.env[:attributes]' do
        actor.create(work)
        expect(work.env[:attributes]).to include(:work_members_attributes)
      end
    end

    context 'when there are no children' do
      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
        allow(lcs).to receive(:list_children).and_return({})
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('list_children_succeeded')
      end
      it 'does not add to work.env[:attributes]' do
        actor.create(work)
        expect(work.env[:attributes]).not_to include(:work_members_attributes)
      end
      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} No children to add.")
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when list_children_service fails' do
      let(:error) { StandardError }

      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
        allow(lcs).to receive(:list_children).and_raise(error)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('list_children_failed')
      end
      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} failed to acquire children.")
      end
    end
  end
end
