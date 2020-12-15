# frozen_string_literal: true

require 'spec_helper'
require 'pry'
require 'rdf'
require 'uri'
require 'rdf/ntriples'
require 'stringio'
require 'hyrax/migrator/preflight_checks'

# OD1 assets
class GenericAsset
  def self.find(pid); end
end

RSpec.describe Hyrax::Migrator::PreflightChecks do
  let(:preflight) { described_class.new('spec/fixtures', 'pidlist', true) }
  let(:work) { double }
  let(:nt) { 'spec/fixtures/3t945r08v/data/3t945r08v_descMetadata.nt' }
  let(:graph) { RDF::Graph.load(nt) }
  let(:workflow) { double }
  let(:services) { {} }
  let(:read_groups) { ['public'] }
  let(:descmeta) { double }

  before do
    allow(GenericAsset).to receive(:find).and_return(work)
    allow(work).to receive(:workflowMetadata).and_return(workflow)
    allow(workflow).to receive(:reviewed).and_return(true)
    allow(workflow).to receive(:destroyed).and_return(false)
    allow(work).to receive(:read_groups).and_return(read_groups)
    allow(work).to receive(:descMetadata).and_return(descmeta)
    allow(descmeta).to receive(:accessRestrictions).and_return([])
    allow(descmeta).to receive(:graph).and_return(graph)
    allow(work).to receive(:pid).and_return('3t945r08v')
  end

  after do
    time = Time.zone.now.strftime('%Y%m%d')
    Dir.glob("spec/fixtures/report_#{time}*").each do |f|
      File.delete(f)
    end
  end

  describe 'verify' do
    context 'when processing a given pid' do
      it 'writes the pid to errors' do
        preflight.verify
        expect(preflight.instance_variable_get(:@errors)).to include 'Working on oregondigital:abcde5678...'
      end

      context 'when there is an error' do
        it 'writes it to errors' do
          preflight.verify
          errors = preflight.instance_variable_get(:@errors)
          err_message = errors.any? { |e| e.start_with? 'Predicate not found' }
          expect(err_message).to equal true
        end
      end

      context 'when an error is caught' do
        let(:error) { StandardError }

        before do
          allow(GenericAsset).to receive(:find).and_raise(error, 'Not found')
        end

        it 'handles the error' do
          preflight.verify
          expect(preflight.instance_variable_get(:@errors)).to include('System error: Not found')
        end
      end
    end
  end

  describe 'status' do
    context 'when there are errors' do
      before do
        allow(workflow).to receive(:destroyed).and_return(true)
      end

      it 'adds the error' do
        preflight.verify
        expect(preflight.instance_variable_get(:@errors)).to include 'status: destroyed'
      end
    end
  end

  describe 'bump_counters' do
    context 'when there is a cpd' do
      let(:cpd_service) { double }

      before do
        allow(Hyrax::Migrator::CpdCheck).to receive(:new).and_return(cpd_service)
        allow(cpd_service).to receive(:work=)
        allow(cpd_service).to receive(:check_cpd).and_return('cpd')
      end

      it 'bumps the counter' do
        preflight.verify
        expect(preflight.instance_variable_get(:@counters)[:cpds]).to eq 2
      end
    end
  end

  describe 'verbose_display' do
    context 'when there are errors and verbose is true' do
      it 'displays them' do
        printed = capture_stdout do
          preflight.verify
        end
        expect(printed).to include('Predicate not found')
      end
    end
  end
end
