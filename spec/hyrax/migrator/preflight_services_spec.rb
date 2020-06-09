# frozen_string_literal: true

require 'spec_helper'
require 'pry'
require 'rdf'
require 'uri'
require 'rdf/ntriples'
require 'stringio'
require 'hyrax/migrator/preflight_services'
# OD1 assets
class GenericAsset
  def self.find(pid); end
end

RSpec.describe Hyrax::Migrator::PreflightService do
  def capture_stdout(&blk)
    old = $stdout
    $stdout = fake = StringIO.new
    blk.call
    fake.string
  ensure
    $stdout = old
  end

  describe 'verify' do
    let(:work) { double }
    let(:nt) { 'spec/fixtures/3t945r08v/data/3t945r08v_descMetadata.nt' }
    let(:datastreams) { double }
    let(:datastream) { double }
    let(:graph) { RDF::Graph.load(nt) }
    let(:workflow) { double }
    let(:service) { Hyrax::Migrator::PreflightServices.new(path, 'pidlist', true) }
    let(:path) { 'spec/fixtures' }

    before do
      allow(GenericAsset).to receive(:find).and_return(work)
      allow(work).to receive(:datastreams).and_return(datastreams)
      allow(datastreams).to receive(:[]).with('descMetadata').and_return(datastream)
      allow(work).to receive(:workflowMetadata).and_return(workflow)
      allow(workflow).to receive(:reviewed).and_return(true)
      allow(workflow).to receive(:destroyed).and_return(false)
      allow(datastream).to receive(:graph).and_return(graph)
    end

    after do
      time = Time.zone.now.strftime('%Y%m%d')
      Dir.glob("spec/fixtures/report_#{time}*").each do |f|
        File.delete(f)
      end
    end

    context 'when there are errors' do
      before do
        service.verify
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
          service.verify
        end

        it 'writes it to file' do
          expect(io).to include('status: unreviewed')
        end
        it 'does not continue and check metadata' do
          expect(work).not_to receive(:datastreams)
        end
      end

      context 'when an asset has been destroyed' do
        before do
          allow(workflow).to receive(:destroyed).and_return(true)
          service.verify
        end

        it 'writes it to file' do
          expect(io).to include('status: destroyed')
        end
      end

      context 'when an error is caught' do
        let(:error) { StandardError }
        let(:io) { IO.read(file.first) }
        let(:file) { Dir.glob('spec/fixtures/report_*') }

        before do
          allow(GenericAsset).to receive(:find).and_raise(error)
          service.verify
        end

        it 'handles the error' do
          expect(io).to include('Could not check')
        end
      end
    end

    context 'when there are valid attributes and verbose is true' do
      it 'displays them' do
        printed = capture_stdout do
          service.verify
        end
        expect(printed).to include('title')
      end
    end
  end
end
