# frozen_string_literal: true

require 'edtf'
require 'hyrax/migrator/edtf_check'
RSpec.describe Hyrax::Migrator::EdtfCheck do
  let(:service) { described_class.new }
  let(:work) { double }
  let(:descMetadata) { double }
  let(:good_date) { ['2021-02-01'] }
  let(:bad_date) { ['2/2/2002'] }

  before do
    service.work = work
    allow(work).to receive(:pid).and_return('abcde1234')
    allow(work).to receive(:descMetadata).and_return(descMetadata)
    allow(service).to receive(:edtf_fields).and_return([:date])
  end

  describe 'check_date_fields' do
    context 'when the date is not edtf' do
      before do
        allow(descMetadata).to receive(:date).and_return(bad_date)
      end

      it 'returns an error' do
        expect(service.check_date_fields).to eq ["in date, #{bad_date.first} is not in EDTF format"]
      end
    end

    context 'when the date is edtf' do
      before do
        allow(descMetadata).to receive(:date).and_return(good_date)
      end

      it 'works' do
        expect(service.check_date_fields).to eq []
      end
    end
  end
end
