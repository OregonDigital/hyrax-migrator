# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'preflight_tools rake tasks' do
  include ActiveJob::TestHelper

  describe 'preflight_tools:preflight' do
    let(:path) { 'spec/fixtures' }
    let(:pidlist) { 'pidlist.txt' }
    let(:service) { double }

    before do
      load_rake_environment [File.expand_path('../../../lib/tasks/preflight_tools/preflight.rake', __dir__), File.expand_path('../../../lib/hyrax/migrator/preflight_checks.rb', __dir__)]
      ENV['work_dir'] = path
      ENV['pidlist'] = 'pidlist.txt'
      allow(Hyrax::Migrator::PreflightChecks).to receive(:new).and_return(service)
      allow(service).to receive(:verify).and_return(nil)
    end

    it 'runs the service' do
      expect(service).to receive(:verify)
      run_task('preflight_tools:preflight')
    end
  end
end
