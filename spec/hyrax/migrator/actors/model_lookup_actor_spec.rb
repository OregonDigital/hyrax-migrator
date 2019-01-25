# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::ModelLookupActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid, file_path: File.join(Rails.root, '..', 'fixtures', pid)) }
  let(:pid) { '3t945r08v' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:model_crosswalk) { File.join(Rails.root, '..', 'fixtures', 'model_lookup.yml') }
  let(:service) { double }

  before do
    config.model_crosswalk = model_crosswalk
    allow(actor).to receive(:config).and_return(config)
  end

  describe '#create' do
    context 'when the validation succeeds' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:model).and_return('Image')
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('model_lookup_succeeded')
      end

      it 'calls the next actor' do
        expect(terminal).to receive(:create)
        actor.create(work)
      end
    end

    context 'when the validation fails' do
      before do
        allow(actor).to receive(:service).and_return(service)
        allow(service).to receive(:model).and_raise(StandardError)
        actor.next_actor = terminal
      end

      it 'updates the work' do
        actor.create(work)
        expect(work.aasm_state).to eq('model_lookup_failed')
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
