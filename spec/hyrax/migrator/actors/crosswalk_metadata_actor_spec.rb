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
        allow(cms).to receive(:crosswalk).and_return(errors: ['Space-time anomaly'])
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('crosswalk_metadata_succeeded')
      end
      it 'stores the error' do
        actor.create(work)
        expect(work.env[:errors].size).to eq 1
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

  describe '#update' do
    context 'when the hash is successfully created' do
      let(:new_attr) { { title: 'Baby Pikachu', date: '1980-08-08', isPartOf: 'So Much Kawaii' } }
      let(:old_attr) { { title: 'Baby Pikachu', date: '1980-08-08', isPartOf: 'Too Much Kawaii' } }

      before do
        allow(actor).to receive(:config).and_return(config)
        allow(Hyrax::Migrator::Services::CrosswalkMetadataService).to receive(:new).and_return(cms)
        allow(cms).to receive(:crosswalk).and_return(new_attr)
        actor.next_actor = terminal
        work.env[:attributes] = old_attr
      end

      it 'updates the work' do
        actor.update(work)
        expect(work.aasm_state).to eq('crosswalk_metadata_succeeded')
      end
      it 'replaces the attrs' do
        actor.update(work)
        expect(work.env[:attributes]).to eq({ isPartOf: 'So Much Kawaii' })
      end
      it 'calls the next actor' do
        expect(terminal).to receive(:update)
        actor.update(work)
      end
    end
  end
end
