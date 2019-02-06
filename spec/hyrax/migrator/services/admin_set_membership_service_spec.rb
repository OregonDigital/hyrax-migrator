# frozen_string_literal: true

require 'rdf'
require 'byebug'

RSpec.describe Hyrax::Migrator::Services::AdminSetMembershipService do
  let(:crosswalk_metadata) do
    h = {}
    h[:primarySet] = RDF::URI('http://oregondigital.org/resource/oregondigital:heavy-rocks')
    h[:set] = [RDF::URI('http://oregondigital.org/resource/oregondigital:little-dogs')]
    h[:set] += [RDF::URI('http://oregondigital.org/resource/oregondigital:heavy-rocks')]
    h[:institution] = [RDF::URI('http://dbpedia.org/resource/University-of-Oregon-State-University')]
    h
  end
  let(:config) { Hyrax::Migrator::Configuration.new }
  let(:pid) { '3t945r08v' }
  let(:file_path) { File.join(Rails.root, '..', 'fixtures', pid) }
  let(:work) { create(:work, pid: pid, file_path: file_path) }
  let(:service) { described_class.new(work, config) }

  before do
  end

  describe 'admin_set' do
    context 'when a primarySet exists' do
      it 'uses the primarySet' do
        expect(service.send(:admin_set, crosswalk_metadata)).to eq 'heavy-rocks'
      end
    end

    context 'when primarySet does not exist' do
      it 'uses a fallback value' do
        expect(service.send(:admin_set, crosswalk_metadata.except(:primarySet))).to eq 'University-of-Oregon-State-University'
      end
    end
  end

  describe 'coll_ids' do
    context 'when given one or more colls' do
      it 'returns an array of the ids' do
        expect(service.send(:coll_ids, crosswalk_metadata)).to eq(['little-dogs', 'heavy-rocks'])
      end
    end

    context 'when there are no colls' do
      it 'returns an empty array' do
        expect(service.send(:coll_ids, crosswalk_metadata.except(:set))).to eq []
      end
    end
  end

  describe 'strip_id' do
    context 'when given an rdf uri' do
      it 'returns an id' do
        expect(service.send(:strip_id, crosswalk_metadata[:primarySet])).to eq 'heavy-rocks'
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

  describe 'get_set_ids' do
    context 'when called' do
      before do
        work.env[:crosswalk_metadata] = crosswalk_metadata
      end

      it 'returns a hash with two members' do
        response = service.crosswalk
        expect(response.size).to eq 2
      end
    end
  end
end
