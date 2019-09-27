# frozen_string_literal:true

module Hyrax::Migrator::Services
  ##
  # A service to add relationships between parent and children in Hyrax
  class AddRelationshipsService
    def initialize(work, user)
      @work = work
      @user = user
    end

    ##
    # Pass the user, model, and attributes to the Hyrax integration class
    # to cause it to persist the work.
    #
    # returns [Boolean] true if the works saved, false if it failed
    def add_relationships
      actor_stack.update
    rescue StandardError => e
      message = "failed to add relationships work #{@work.pid}, #{e.message}"
      Rails.logger.error message
      raise StandardError, message
    end

    private

    def actor_stack
      @actor_stack ||= Hyrax::Migrator::HyraxCore::ActorStack.new(
        user: @user,
        model: @work.env[:model],
        attributes: attributes
      )
    end

    def attributes
      attrs = @work.env[:attributes].slice(:work_members_attributes).merge(id: @work.pid)
      attrs.merge(ordered_member_ids: ordered_member_ids)
    end

    def ordered_member_ids
      @work.env[:attributes][:work_members_attributes].map { |_k, v| v['id'] }
    end
  end
end
