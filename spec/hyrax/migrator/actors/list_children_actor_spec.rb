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

      it 'calls list_children_succeeded' do
        expect(actor).to receive(:post_success)
        actor.create(work)
      end
    end

    context 'when there are no children' do
      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
        allow(lcs).to receive(:list_children).and_return({})
        actor.next_actor = terminal
      end

      it 'calls list_children_succeeded' do
        expect(actor).to receive(:post_success)
        actor.create(work)
      end
    end

    context 'when list_children_service does not return a hash' do
      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
        allow(lcs).to receive(:list_children).and_return(nil)
        actor.next_actor = terminal
      end

      it 'calls list_children_failed' do
        expect(actor).to receive(:post_fail)
        actor.create(work)
      end
    end

    context 'when list_children_service errors' do
      let(:error) { StandardError }

      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
        allow(lcs).to receive(:list_children).and_raise(error)
        actor.next_actor = terminal
      end

      it 'calls list_children_failed' do
        expect(actor).to receive(:post_fail)
        actor.create(work)
      end
      it 'logs the failure' do
        expect(Rails.logger).to receive(:warn)
        actor.create(work)
      end
    end
  end

  describe '#post_success' do
    before do
      allow(actor).to receive(:config).and_return(config)
      allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
      allow(lcs).to receive(:list_children).and_return(result_hash)
      actor.next_actor = terminal
    end

    context 'when children have been returned' do
      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('list_children_succeeded')
      end
      it 'sets the status' do
        actor.create(work)
        expect(work.status).to eq('success')
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
        expect(work.env).to include(:work_members_attributes)
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
      it 'sets the status' do
        actor.create(work)
        expect(work.status).to eq('success')
      end
      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} No children to add.")
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
      it 'does not add to work.env' do
        actor.create(work)
        expect(work.env).not_to include(:work_members_attributes)
      end
    end
  end

  describe '#post_fail' do
    context 'when a failure is called' do
      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::ListChildrenService).to receive(:new).and_return(lcs)
        allow(lcs).to receive(:list_children).and_return(nil)
        actor.next_actor = terminal
      end

      it 'updates the status in the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('list_children_failed')
      end
      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
      it 'sets the status' do
        actor.create(work)
        expect(work.status).to eq('fail')
      end
      it 'sets the status message' do
        actor.create(work)
        expect(work.status_message).to eq("Work #{work.pid} failed to acquire children.")
      end
    end
  end
end
