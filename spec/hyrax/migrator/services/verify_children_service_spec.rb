# frozen_string_literal: true

RSpec.describe Hyrax::Migrator::Services::VerifyChildrenService do
  let(:migrated_work) { double }
  let(:migrator_work) { double }
  let(:hyrax_work) { double }
  let(:service) { described_class.new(migrated_work) }

  before do
    allow(migrated_work).to receive(:work).and_return(migrator_work)
    allow(migrated_work).to receive(:asset).and_return(hyrax_work)
    allow(migrated_work).to receive(:original_profile).and_return(original_profile)
    allow(hyrax_work).to receive(:ordered_member_ids).and_return(member_ids)
  end

  describe 'verify_children when there are children' do
    let(:original_profile) do
      str = "contents:\n"
      str += "- df70j709q\n"
      str += "- df70j710g\n"
      YAML.safe_load(str)
    end

    context 'when all children are present and in order' do
      let(:member_ids) { %w[df70j709q df70j710g] }

      it 'returns empty' do
        expect(service.verify).to eq []
      end
    end

    context 'when all children are present but out of order' do
      let(:member_ids) { %w[df70j710g df70j709q] }

      it 'returns the first wrongly placed child' do
        expect(service.verify).to eq ['df70j710g is out of order']
      end
    end

    context 'when not all children are present' do
      let(:member_ids) { %w[df70j709q] }

      it 'returns a list of missing children' do
        expect(service.verify).to eq ['df70j710g missing;']
      end
    end

    context 'when one of the children is nil' do
      let(:member_ids) { ['df70j709q', nil] }

      it 'returns a list of missing children' do
        expect(service.verify).to eq ['df70j710g missing;']
      end
    end
  end

  describe 'verify children' do
    let(:member_ids) { [] }
    let(:original_profile) do
      str = "otherstuff:\n"
      str += "- thing1\n"
      YAML.safe_load(str)
    end

    context 'when there are no children' do
      it 'returns empty errors' do
        expect(service.verify).to eq []
      end
    end
  end
end
