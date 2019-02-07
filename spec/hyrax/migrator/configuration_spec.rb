# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Configuration do
  let(:conf) { build(:configuration) }

  it { expect(conf.models).to eq [] }
  it { expect(conf.mount_at).to be_a String }
  it { expect(conf.queue_name).to be_a String }
  it { expect(conf.logger).to be_a Logger }
  it { expect(conf.crosswalk_metadata_file).to be_a String }
  it { expect(conf.model_crosswalk).to be_a String }
  it { expect(conf.migration_user).to be_a String }

  context 'when registering a model' do
    before do
      conf.register_model('test')
    end

    it { expect(conf.models).to eq ['test'] }
  end
end
