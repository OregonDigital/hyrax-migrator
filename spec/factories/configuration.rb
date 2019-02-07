# frozen_string_literal:true

FactoryBot.define do
  factory :configuration, class: 'Hyrax::Migrator::Configuration' do
    mount_at { '/migrator' }
    queue_name { 'migrator' }
    logger { Logger.new(STDOUT) }
    crosswalk_metadata_file { '/some/path/file' }
    model_crosswalk { '/some/path/file' }
    migration_user { 'admin@example.org' }
  end
end
