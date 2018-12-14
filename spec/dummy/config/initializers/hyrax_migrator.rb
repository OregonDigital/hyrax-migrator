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
end
