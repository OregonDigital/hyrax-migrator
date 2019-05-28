# frozen_string_literal: true

require 'rdf'
require 'byebug'

RSpec.describe Hyrax::Migrator::Services::AdminSetMembershipService do
  let(:crosswalk_metadata) do
    h = {}
    h[:institution] = [RDF::URI('http://dbpedia.org/resource/University-of-Oregon-State-University')]
    h[:repository] = [RDF::URI('http://dbpedia.org/resource/Hogwarts-Special-Collections-and-Archives')]
    h
  end
  let(:metadata_set) { ['http://oregondigital.org/resource/oregondigital:little-dogs', 'http://oregondigital.org/resource/oregondigital:heavy-rocks'] }
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:pid) { '3t945r08v' }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:service) { described_class.new(work, config) }

  let(:hyrax_core_admin_set) { instance_double('Hyrax::Migrator::HyraxCore::AdminSet') }
  let(:admin_set) { instance_double('AdminSet', id: 'osu', title: 'University', description: 'hello world') }

  before do
    config.crosswalk_admin_sets_file = File.join(Rails.root, '../fixtures/crosswalk_admin_sets.yml')
    allow(Hyrax::Migrator::HyraxCore::AdminSet).to receive(:find).with(anything).and_return(admin_set)
  end

  describe 'admin_set' do
    before do
      allow(service).to receive(:match_admin_set_id).and_return('heavy-rocks')
    end

    context 'when a primary_set exists' do
      let(:admin_set) { instance_double('AdminSet', id: 'heavy-rocks', title: 'University', description: 'hello world') }

      it 'uses the primary_set' do
        expect(service.send(:admin_set, crosswalk_metadata)).to eq 'heavy-rocks'
      end
    end

    context 'when primary_set does not exist' do
      let(:admin_set) { instance_double('AdminSet', id: 'University-of-Oregon-State-University', title: 'University', description: 'Hello world') }

      it 'uses a fallback value' do
        expect(service.send(:admin_set, crosswalk_metadata.except(:primary_set))).to eq 'University-of-Oregon-State-University'
      end
    end

    context 'when primary_set and institution do not exist' do
      let(:admin_set) { instance_double('AdminSet', id: 'Hogwarts-Special-Collections-and-Archives', title: 'University', description: 'hello world') }

      it 'uses a fallback value' do
        expect(service.send(:admin_set, crosswalk_metadata.except(:primary_set, :institution))).to eq 'Hogwarts-Special-Collections-and-Archives'
      end
    end

    context 'when none of the possible set values exist' do
      before do
        allow(service).to receive(:metadata_primary_set).and_return(nil)
      end

      it 'uses a default value' do
        expect(service.send(:admin_set, crosswalk_metadata.except(:primary_set, :institution, :repository))).to eq 'admin/default'
      end
    end
  end

  describe 'collection_ids' do
    context 'when given one or more colls' do
      let(:result) { { '0' => { 'id' => 'little-dogs' }, '1' => { 'id' => 'heavy-rocks' } } }

      before do
        allow(service).to receive(:metadata_set).and_return(metadata_set)
      end

      it 'returns an hash of the ids' do
        expect(service.send(:collection_ids)).to eq(result)
      end
    end

    context 'when there are no colls' do
      before do
        allow(service).to receive(:metadata_set).and_return([])
      end

      it 'returns an empty hash' do
        expect(service.send(:collection_ids)).to eq({})
      end
    end
  end

  describe 'strip_id' do
    context 'when given an rdf uri' do
      it 'returns an id' do
        expect(service.send(:strip_id, crosswalk_metadata[:institution].first)).to eq 'University-of-Oregon-State-University'
      end
    end

    context 'when given an rdf literal that is a uri' do
      let(:lit) { RDF::Literal('http://oregondigital.org/resource/heavy-rocks') }

      it 'still returns an id' do
        expect(service.send(:strip_id, lit)).to eq 'heavy-rocks'
      end
    end

    context 'when given an rdf literal that is not a uri' do
      let(:lit) { RDF::Literal('heavy-rocks') }

      it 'returns an id' do
        expect(service.send(:strip_id, lit)).to eq 'heavy-rocks'
      end
    end
  end

  describe 'acquire_set_ids' do
    context 'when called' do
      before do
        work.env[:crosswalk_metadata] = crosswalk_metadata
      end

      it 'returns a hash with two members' do
        response = service.acquire_set_ids
        expect(response.keys).to eq %w[admin_set_id member_of_collections_attributes]
      end
    end
  end

  describe 'admin_set_id' do
    let(:admin_set) { instance_double('AdminSet', id: 'osu', title: 'Oregon State University', description: 'hello world') }

    before do
      crosswalk_metadata[:primary_set] = RDF::URI('http://oregondigital.org/resource/oregondigital:columbia-gorge')
      crosswalk_metadata[:institution] = [RDF::URI('http://dbpedia.org/resource/Oregon-State-University')]
      crosswalk_metadata[:repository] = [RDF::URI('http://dbpedia.org/resource/Test')]
    end

    context 'when called' do
      it 'returns corresponding admin set id' do
        expect(service.send(:admin_set_id, crosswalk_metadata[:primary_set])).to eq 'osu'
      end
    end
  end
end
