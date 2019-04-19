# frozen_string_literal: true

require 'rdf'

RSpec.describe Hyrax::Migrator::Actors::CrosswalkMetadataActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid) }
  let(:pid) { 'abcde1234' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:cms) { instance_double('Hyrax::Migrator::Services::CrosswalkMetadataService') }

  describe '#create' do
    context 'when the hash is successfully created' do
      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::CrosswalkMetadataService).to receive(:new).and_return(cms)
        allow(cms).to receive(:crosswalk).and_return({})
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('crosswalk_metadata_succeeded')
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the crosswalk_metadata_service fails' do
      let(:error) { StandardError }

      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::CrosswalkMetadataService).to receive(:new).and_return(cms)
        allow(cms).to receive(:crosswalk).and_raise(error)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('crosswalk_metadata_failed')
      end
      it 'does not call the next actor' do
        expect(terminal).not_to receive(:create)
        actor.create(work)
      end
    end
  end
end
