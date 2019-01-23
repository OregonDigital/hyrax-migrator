# frozen_string_literal:true
require 'bagit'

RSpec.describe Hyrax::Migrator::Work do
  let(:pid) { 'abcde1234' }
  let(:model) { create(:work, file_path: File.join(Rails.root, '..', 'fixtures', pid)) }

  it { expect(model.env).to be_a Hash }
  it { expect(model.bag).to be_a BagIt::Bag }
end
