# frozen_string_literal: true

require 'rdf'
require 'uri'
require 'hyrax/migrator/crosswalk_metadata'

RSpec.describe Hyrax::Migrator::Services::CrosswalkMetadataService do
  let(:graph) do
    g = RDF::Graph.new
    s = RDF::Statement.new(rdfsubject, predicate, rdfobject)
    g << s
    g
  end
  let(:rdfsubject) { RDF::URI('http://oregondigital.org/resource/oregondigital:abcde1234') }

  let(:predicate_str) { 'http://purl.org/dc/terms/subject' }
  let(:predicate) { RDF::URI(predicate_str) }
  let(:rdfobject) { RDF::URI('http://opaquenamespace.org/ns/subject/AnagonyeChidi') }
  let(:data) { { property: 'subject_attributes', predicate: predicate_str, multiple: true, function: 'attributes_data' } }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:crosswalk_metadata_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk.yml') }
  let(:crosswalk_overrides_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk_overrides.yml') }
  let(:crosswalk_admin_sets_file) { File.join(Rails.root, '..', 'fixtures', 'crosswalk_admin_sets.yml') }
  let(:service) { described_class.new(work, config) }
  let(:pid) { '3t945r08v' }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }

  before do
    config.crosswalk_metadata_file = crosswalk_metadata_file
    config.crosswalk_overrides_file = crosswalk_overrides_file
    config.crosswalk_admin_sets_file = crosswalk_admin_sets_file
    allow(RDF::Graph).to receive(:load).and_return(graph)
  end

  describe 'lookup' do
    let(:predicate) { RDF::URI('http://badpredicates.org/ns/bad') }
    let(:error) { Hyrax::Migrator::Services::CrosswalkMetadataService::PredicateNotFoundError }

    context 'when the result is nil' do
      it 'raises an error' do
        expect { service.send(:lookup, predicate.to_s) }.to raise_error(error)
      end

      context 'when skip_field_mode is enabled' do
        before do
          config.skip_field_mode = true
          service.send(:lookup, predicate.to_s)
        end

        it 'reports the error' do
          expect(service.instance_variable_get(:@errors).size).to eq 1
        end
      end
    end
  end

  describe 'crosswalk' do
    context 'when there is valid metadata' do
      it 'returns results' do
        expect(service.crosswalk[:subject_attributes]).to eq [{ '_destroy' => 0, 'id' => 'http://opaquenamespace.org/ns/subject/AnagonyeChidi' }]
      end
    end

    context 'when there are errors' do
      let(:predicate) { RDF::URI('http://badpredicates.org/ns/bad') }

      it 'reports them' do
        service.crosswalk
      rescue Hyrax::Migrator::Services::CrosswalkMetadataService::PredicateNotFoundError
        result = service.instance_variable_get(:@result)
        expect(result[:errors].size).to eq 1
      end
    end
  end

  describe 'update' do
    let(:old_env) do
      { title: ['The Tragedy of Hamlet, Prince of Denmark'],
        subject_attributes: [{ 'id' => 'http://id.loc.gov/authorities/names/n79021597', '_destroy' => 0 }, { 'id' => 'http://id.loc.gov/authorities/subjects/sh85121053', '_destroy' => 0 }],
        creator_attributes: [{ 'id' => 'http://id.loc.gov/authorities/names/n78095332', '_destroy' => 0 }],
        alternate: ['Hamlet'] }
    end
    let(:graph) do
      g = RDF::Graph.new
      g << RDF::Statement.new(rdfsubject, RDF::URI('http://purl.org/dc/terms/title'), 'Rosencrantz and Guildenstern Are Dead') # change in title
      g << RDF::Statement.new(rdfsubject,  RDF::URI('http://purl.org/dc/terms/subject'), RDF::URI('http://id.loc.gov/authorities/subjects/sh85134575')) # addition to subject
      g << RDF::Statement.new(rdfsubject,  RDF::URI('http://purl.org/dc/terms/subject'), RDF::URI('http://id.loc.gov/authorities/names/n79021597')) # one subject retained, the other is removed
      g # creator and alternative are removed
    end

    before do
      work.env[:attributes] = old_env
      work.save
    end

    context 'when there is a change in a string field' do
      it 'includes the change' do
        expect(service.update[:title]).to eq ['Rosencrantz and Guildenstern Are Dead']
      end
    end

    context 'when there is an addition to a controlled field' do
      it 'adds the new value' do
        expect(service.update[:subject_attributes]).to include({ 'id' => 'http://id.loc.gov/authorities/subjects/sh85134575', '_destroy' => 0 })
      end
    end

    context 'when a string field is removed' do
      it 'unsets the field' do
        expect(service.update[:alternate]).to eq []
      end
    end

    context 'when a controlled field becomes empty' do
      it 'marks the contained val as destroyed' do
        expect(service.update[:creator_attributes]).to eq [{ 'id' => 'http://id.loc.gov/authorities/names/n78095332', '_destroy' => 1 }]
      end
    end

    context 'when a controlled value is removed from a field' do
      it 'marks the contained val as destroyed' do
        expect(service.update[:subject_attributes]).to include({ 'id' => 'http://id.loc.gov/authorities/subjects/sh85121053', '_destroy' => 1 })
      end
    end
  end

  describe 'attributes_data' do
    let(:rdfobject) { RDF::Literal('blah blah') }
    let(:error) { URI::InvalidURIError }

    it 'raises an error' do
      expect { service.send(:attributes_data, rdfobject) }.to raise_error(error)
    end

    context 'when skip field mode is enabled' do
      before do
        config.skip_field_mode = true
      end

      it 'adds errors to the result' do
        service.send(:attributes_data, rdfobject)
        expect(service.instance_variable_get(:@errors).size).to eq 1
      end
      it 'returns nil' do
        expect(service.send(:attributes_data, rdfobject)).to eq nil
      end
    end
  end

  describe 'cv_attrs' do
    let(:attributes) do
      hash = {}
      hash[:visibility] = 'open'
      hash[:admin_set_id] = 'spike-spiegel-papers'
      hash[:title] = ['Aardvark a mile for one of your smiles']
      hash
    end

    before do
      allow(work.env).to receive(:[]).with(:attributes).and_return(attributes)
    end

    it 'does not include attrs set by other services' do
      expect(service.send(:old_attrs).keys).not_to include(:visibility)
    end
  end

  describe 'log_info' do
    let(:object) { 'May 13, 2015' }

    it 'adds the object to the result' do
      service.send(:log_info, object)
      expect(service.instance_variable_get(:@info)).to eq [object]
    end
  end

  describe 'full_size_hack' do
    let(:object) { 'angelus-studio' }

    before do
      service.result[:full_size_download_allowed] = true
    end

    it 'sets the permission' do
      service.send(:full_size_hack, object)
      expect(service.result[:full_size_download_allowed]).to eq false
    end
  end
end
