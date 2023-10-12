# frozen_string_literal:true

RSpec.describe Hyrax::Migrator::Middleware::Configuration do
  subject { object }

  let(:object) { described_class.new }
  let(:default_actor_stack) do
    [
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
      Hyrax::Migrator::Actors::AddCollectionPermissionActor,
      Hyrax::Migrator::Actors::WorkflowMetadataActor,
      Hyrax::Migrator::Actors::TerminalActor
    ]
  end

  it { is_expected.to respond_to(:actor_stack) }
  it { expect(object.actor_stack).to eq default_actor_stack }
end
