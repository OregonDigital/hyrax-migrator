# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'pry'
require 'rdf'
require 'uri'
require 'rdf/ntriples'
require 'hyrax/migrator/crosswalk_metadata_preflight'
require 'hyrax/migrator/required_fields'

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
    let(:workflow) { double }

    before do
      load_rake_environment [File.expand_path('../../../lib/tasks/preflight_tools/metadata_preflight.rake', __dir__), File.expand_path('../../../lib/hyrax/migrator/crosswalk_metadata_preflight.rb', __dir__), File.expand_path('../../../lib/hyrax/migrator/required_fields.rb', __dir__), File.expand_path('../../../lib/hyrax/migrator/asset_status.rb', __dir__)]
      allow(GenericAsset).to receive(:find).and_return(work)
      allow(work).to receive(:datastreams).and_return(datastreams)
      allow(datastreams).to receive(:[]).with('descMetadata').and_return(datastream)
      allow(work).to receive(:workflowMetadata).and_return(workflow)
      allow(workflow).to receive(:reviewed).and_return(true)
      allow(workflow).to receive(:destroyed).and_return(false)
      allow(datastream).to receive(:graph).and_return(graph)
      ENV['work_dir'] = 'spec/fixtures'
      ENV['pidlist'] = 'pidlist'
    end

    after do
      time = Time.zone.now.strftime('%Y%m%d')
      Dir.glob("spec/fixtures/report_#{time}*").each do |f|
        File.delete(f)
      end
    end

    context 'when there are errors' do
      before do
        run_task('preflight_tools:metadata_preflight')
      end

      let(:io) { IO.read(file.first) }
      let(:file) { Dir.glob('spec/fixtures/report_*') }

      context 'when a predicate is missing' do
        it 'writes it to file' do
          expect(io).to include('Predicate not found')
        end
      end

      context 'when a field is missing' do
        it 'writes it to file' do
          expect(io).to include('missing required field: identifier')
        end
      end

      context 'when a field is not missing' do
        it 'does not write it to file' do
          expect(io).not_to include('missing required field: title')
        end
      end
    end

    context 'when an asset status is not ok' do
      let(:io) { IO.read(file.first) }
      let(:file) { Dir.glob('spec/fixtures/report_*') }

      context 'when an asset has not been reviewed' do
        before do
          allow(workflow).to receive(:reviewed).and_return(false)
          run_task('preflight_tools:metadata_preflight')
        end

        it 'writes it to file' do
          expect(io).to include('status: unreviewed')
        end
      end

      context 'when an asset has been destroyed' do
        before do
          allow(workflow).to receive(:destroyed).and_return(true)
          run_task('preflight_tools:metadata_preflight')
        end

        it 'writes it to file' do
          expect(io).to include('status: destroyed')
        end
      end
    end

    context 'when there are valid attributes and verbose is true' do
      before do
        ENV['verbose'] = 'true'
      end

      it 'displays them' do
        stdio = run_task('preflight_tools:metadata_preflight')
        expect(stdio).to include('title')
      end
    end
  end
end
