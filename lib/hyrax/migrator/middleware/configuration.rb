# frozen_string_literal:true

# rubocop:disable Metrics/MethodLength
module Hyrax
  module Migrator
    module Middleware
      ##
      # Configurations for the middleware
      class Configuration
        ##
        # The list of actors which need to process a work through
        # migration in the order provided. If there is no intializer
        # set, the default is provided.
        attr_writer :actor_stack
        def actor_stack
          # TODO: Replace this with a valid default stack of actors for
          # processing a work through migration.
          @actor_stack ||= [
            Hyrax::Migrator::Actors::CrosswalkMetadataActor,
            Hyrax::Migrator::Actors::RequiredFieldsActor,
            Hyrax::Migrator::Actors::ModelLookupActor,
            Hyrax::Migrator::Actors::AdminSetMembershipActor,
            Hyrax::Migrator::Actors::VisibilityLookupActor,
            Hyrax::Migrator::Actors::FileUploadActor,
            Hyrax::Migrator::Actors::ListChildrenActor,
            Hyrax::Migrator::Actors::ChildrenAuditActor,
            Hyrax::Migrator::Actors::PersistWorkActor,
            Hyrax::Migrator::Actors::AddRelationshipsActor,
            Hyrax::Migrator::Actors::WorkflowMetadataActor,
            Hyrax::Migrator::Actors::TerminalActor
          ]
        end
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
