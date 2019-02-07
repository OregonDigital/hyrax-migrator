# frozen_string_literal:true

Hyrax::Migrator::Middleware.config do |config|
  # A custom ordered array of actors to process a work through migration.
  # config.actor_stack = [MyModule::ActorOne, MyModule::ActorTwo]
end

Hyrax::Migrator.config do |config|
  # The location to mount the migration application to, `migrator` would mount at http://domain/migrator
  # config.mount_at = 'migrator'

  # The redis queue name for background jobs to run in
  # config.queue_name = 'hyrax_migrator'

  # Set a specific logger for the engine to use
  config.logger = Rails.logger

  # Register models for migration
  # config.register_model ::Models::Image
  config.register_model String

  # Migration user
  config.migration_user = 'admin@example.org'

  # The model crosswalk used by ModelLookupService
  config.model_crosswalk = File.join(Rails.root, '../fixtures/model_crosswalk.yml')

  # The crosswalk metadata file that lists properties and predicates
  config.crosswalk_metadata_file = File.join(Rails.root, '../fixtures/crosswalk.yml')
end
