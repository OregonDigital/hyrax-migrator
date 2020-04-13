# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'pry'
require 'rdf'
require 'uri'
require 'rdf/ntriples'
require 'hyrax/migrator/crosswalk_metadata'

# OD1 assets
class GenericAsset
  def self.find(pid); end
end

RSpec.describe 'preflight_tools rake tasks' do
  include ActiveJob::TestHelper
  describe 'preflight_tools:metadata_preflight' do
    let(:work) { double }
    let(:nt) { 'spec/fixtures/3t945r08v/data/3t945r08v_descMetadata.nt' }
    let(:datastreams) { double }
    let(:datastream) { double }
    let(:graph) { RDF::Graph.load(nt) }

    before do
      load_rake_environment [File.expand_path('../../../lib/tasks/preflight_tools/metadata_preflight.rake', __dir__), File.expand_path('../../../lib/hyrax/migrator/crosswalk_metadata.rb', __dir__)]
      allow(GenericAsset).to receive(:find).and_return(work)
      allow(work).to receive(:datastreams).and_return(datastreams)
      allow(datastreams).to receive(:[]).with('descMetadata').and_return(datastream)
      allow(datastream).to receive(:graph).and_return(graph)
      ENV['work_dir'] = 'spec/fixtures'
      ENV['pidlist'] = 'pidlist'
    end

    after do
      time = Time.now.strftime('%Y%m%d')
      Dir.glob("spec/fixtures/report_#{time}*").each do |f|
        File.delete(f)
      end
    end

    context 'when there are errors' do
      it 'writes them to a file' do
        run_task('preflight_tools:metadata_preflight')
        file = Dir.glob('spec/fixtures/report_*')
        expect(IO.read(file.first)).to include('Predicate not found')
      end
    end

    context 'when there are valid attributes and verbose is true' do
      before do
        ENV['verbose'] = 'true'
      end

      it 'displays them' do
        stdio = run_task('preflight_tools:metadata_preflight')
        expect(stdio).to include('Attributes')
      end
    end
  end
end
