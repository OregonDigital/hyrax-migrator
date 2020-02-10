# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'pry'
require 'rdf'
require 'uri'
require 'rdf/ntriples'
require 'hyrax/migrator/crosswalk_metadata'

class GenericAsset
  def self.find(pid); end
end

RSpec.describe 'preflight_tools rake tasks' do
  include ActiveJob::TestHelper
  describe 'preflight_tools:metadata_preflight' do
    let(:work) { double }
    let(:nt) { 'spec/fixtures/3t945r08v/data/3t945r08v_descMetadata.nt' }
    let(:graph) { RDF::Graph.load(nt) }
    let(:run_rake_task) do
      ENV['work_dir'] = 'spec/fixtures'
      ENV['pidlist'] = 'pidlist'
      Rake.application.invoke_task 'preflight_tools:metadata_preflight'
    end

    before do
      load_rake_environment [File.expand_path('../../../lib/tasks/preflight_tools/metadata_preflight.rake', __dir__), File.expand_path('../../../lib/hyrax/migrator/crosswalk_metadata.rb', __dir__)]
      allow(GenericAsset).to receive(:find).and_return(work)
      allow(work).to receive(:datastreams).and_return(nt)
      allow(RDF::Graph).to receive(:load).and_return(graph)
      run_rake_task
    end

    after do
      time = Time.now.strftime('%Y%m%d')
      Dir.glob("spec/fixtures/report_#{time}*").each do |f|
        File.delete(f)
      end
    end

    context 'when there are errors' do
      it 'writes them to a file' do
        file = Dir.glob('spec/fixtures/report_*')
        expect(IO.read(file.first)).to include('Predicate not found')
      end
    end
  end
end
