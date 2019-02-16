# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    # Access the Hyrax actor stack for work persistence
    class ActorStack
      ##
      # Given the work being processed, fire off the hyrax actor stack to
      # persist and process it through ingest.
      #
      # @param [Hash] args :
      #   user: the migration user
      #   model: the string name of the model being created
      #   attributes: a hash of the migrator Work#env (all migrator processing attributes)
      #
      # @see https://github.com/samvera/hyrax/blob/master/app/actors/hyrax/actors/environment.rb
      def initialize(args)
        @user = args[:user]
        @model = args[:model]
        @attributes = args[:attributes]
      end

      # Cause the Hyrax actor stack to ingest this work
      # @return [Boolean] - true if create was successful, false if failed
      def create
        actor.create(actor_environment)
      rescue StandardError => e
        logger.error(e.message)
        raise e
      end

      # Cause the Hyrax actor stack to update an existing
      # @return [Boolean] - true if update was successful, false if failed
      def update
        actor.update(actor_environment)
      rescue StandardError => e
        logger.error(e.message)
        raise e
      end

      private

      def logger
        @logger ||= Rails.logger
      end

      ## No coverage for Hyrax application integration to eliminate dependencies
      # :nocov:
      def actor
        @actor ||= Hyrax::CurationConcern.actor
      end

      def actor_environment
        @actor_environment = Hyrax::Actors::Environment.new(curation_concern, @user.ability, @attributes)
      end

      def curation_concern
        # TODO: find or .new the model if the attributes have an id?
        @curation_concern ||= @model.constantize.new
      end
      # :nocov:
    end
  end
end
