# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/migrator/preflight_check_services'

RSpec.describe Hyrax::Migrator::PreflightCheckServices do
  let(:service) { described_class.new({}, 'dir', 'list') }
  let(:crosswalk) { double }
  let(:required) { double }
  let(:cpd) { double }
  let(:visibility) { double }
  let(:status) { double }
  let(:work) { double }
  let(:edtf) { double }

  before do
    allow(Hyrax::Migrator::CrosswalkMetadataPreflight).to receive(:new).and_return(crosswalk)
    allow(Hyrax::Migrator::RequiredFields).to receive(:new).and_return(required)
    allow(Hyrax::Migrator::AssetStatus).to receive(:new).and_return(status)
    allow(Hyrax::Migrator::VisibilityLookupPreflight).to receive(:new).and_return(visibility)
    allow(Hyrax::Migrator::CpdCheck).to receive(:new).and_return(cpd)
    allow(Hyrax::Migrator::EdtfCheck).to receive(:new).and_return(edtf)
    allow(crosswalk).to receive(:crosswalk)
    allow(crosswalk).to receive(:work=).with(work)
  end

  describe 'run' do
    it 'calls the correct command on all listed services' do
      expect(crosswalk).to receive(:crosswalk)
      service.run([:crosswalk])
    end
  end

  describe 'reset' do
    it 'resets the correct property with the passed argument on the listed services' do
      expect(crosswalk).to receive(:work=).with(work)
      service.reset([:crosswalk], work)
    end
  end
end
