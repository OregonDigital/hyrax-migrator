# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::MigrateWorkService do
  let(:service) { described_class.new(pid: pid, file_path: file_path) }
  let!(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:pid) { 'abcde1234' }
  let(:file_path) { 'tmp/test_file.zip' }

  it { expect(service.work).to eq work }
  it { expect(service.middleware).to be_a Hyrax::Migrator::Middleware::DefaultMiddleware }

  describe 'creating a new work while running the service' do
    let(:service) { described_class.new(pid: new_pid, file_path: file_path) }
    let(:new_pid) { 'newonehere' }

    it { expect(service.work.pid).to eq new_pid }
    it { expect(service.work.env[:attributes][:id]).to eq new_pid }
  end

  describe 'running the service' do
    let(:middleware) { double }

    before do
      allow(service).to receive(:middleware).and_return(middleware)
    end

    context 'when creating' do
      it do
        allow(middleware).to receive(:start).with(work).and_return(true)
        expect(service).to receive(:work).and_return(work)
        service.run
      end
      it do
        allow(service).to receive(:work).and_return(work)
        expect(middleware).to receive(:start).with(work)
        service.run
      end
    end

    context 'when updating' do
      let(:service) { described_class.new(pid: pid, file_path: file_path, update: true) }

      it do
        allow(middleware).to receive(:update).with(work).and_return(true)
        expect(service).to receive(:work).and_return(work)
        service.run
      end
      it do
        allow(service).to receive(:work).and_return(work)
        expect(middleware).to receive(:update).with(work)
        service.run
      end
    end
  end

  describe 'running the service with a custom config' do
    let(:service) { described_class.new(pid: pid, file_path: file_path, middleware_config: middleware_config) }
    let(:middleware_config) { { actor_stack: ['Hyrax::Migrator::Actors::ListChildrenActor'] } }
    let(:config) do
      c = Hyrax::Migrator::Middleware::Configuration.new
      c.actor_stack = [Hyrax::Migrator::Actors::ListChildrenActor]
      c
    end
    let(:middleware) { Hyrax::Migrator::Middleware.custom(config) }

    it 'calls the custom middleware' do
      expect(service).to receive(:middleware).and_return(middleware)
      service.run
    end
  end
end
