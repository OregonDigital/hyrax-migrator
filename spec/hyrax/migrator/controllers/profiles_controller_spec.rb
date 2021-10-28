# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::ProfilesController, type: :controller do
  routes { Hyrax::Migrator::Engine.routes }
  let(:subject) { described_class }
  let(:work) { instance_double('Hyrax::Migrator::Work', id: pid, working_directory: 'spec/fixtures') }
  let(:pid) { 'df70jh899' }
  let(:hyrax_work) { instance_double('Image', member_of_collections: [coll], as_json: field_hash, visibility: 'open') }
  let(:uri) { 'http://id.loc.gov/authorities/subjects/sh85023341' }
  let(:controlled_vocab) { instance_double('Controlled Vocabulary', rdf_subject: RDF::URI(uri)) }
  let(:coll) { instance_double('Collection', id: 'kawaii') }
  let(:field_hash) do
    hash = { 'subject': [controlled_vocab] }
    hash['title'] = ['Obaachan']
    hash['original_filename'] = 'obaachan'
    hash
  end
  let(:result_hash) do
    hash = { 'subject': [uri] }
    hash['title'] = ['Obaachan']
    hash['original_filename'] = 'obaachan'
    hash
  end

  before do
    allow(Hyrax::Migrator::Work).to receive(:find_by).with({ pid: pid }).and_return(work)
    allow(Hyrax::Migrator::HyraxCore::Asset).to receive(:find).with(pid).and_return(hyrax_work)
    get :show, params: { id: pid }
  end

  describe 'fields' do
    it 'has fields' do
      expect(controller.instance_variable_get(:@fields)).to eq(result_hash)
    end
  end

  describe 'show' do
    it 'shows' do
      expect(response).to be_success
    end
  end
end
