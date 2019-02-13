# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Actors::FileUploadActor do
  let(:actor) { described_class.new }
  let(:terminal) { Hyrax::Migrator::Actors::TerminalActor.new }
  let(:work) { create(:work, pid: pid, file_path: File.join(Rails.root, '..', 'fixtures', pid)) }
  let(:pid) { '3t945r08v' }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:service) { double }

  before do
    allow(actor).to receive(:config).and_return(config)
  end

  describe '#create' do
  end
end 