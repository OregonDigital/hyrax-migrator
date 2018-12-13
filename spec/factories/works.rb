# frozen_string_literal:true

FactoryBot.define do
  factory :work, class: 'Hyrax::Migrator::Work' do
    sequence(:pid) { |n| "pid#{n}" }
    file_path { '/some/path/file' }
    aasm_state { 'state' }
    status_message { 'Migrated!' }
    status { 'succeeded' }
    env { { key: 'value', another_key: 'value' } }
  end
end
