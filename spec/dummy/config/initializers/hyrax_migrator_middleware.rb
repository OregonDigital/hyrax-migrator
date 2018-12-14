# frozen_string_literal:true

Hyrax::Migrator::Middleware.config do |config|
  # A custom ordered array of actors to process a work through migration.
  # config.actor_stack = [MyModule::ActorOne, MyModule::ActorTwo]
end
