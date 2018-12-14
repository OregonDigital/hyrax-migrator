# frozen_string_literal:true

require 'aasm'

module Hyrax::Migrator::Actors
  ##
  # Abstract class that actors should inherit from
  class AbstractActor
    include AASM

    ##
    # @!attribute next_actor [r]
    #   @return [AbstractActor]
    attr_reader :next_actor

    ##
    # @param next_actor [AbstractActor]
    def initialize(next_actor)
      @next_actor = next_actor
    end

    ##
    # Call the next actor, passing the env along for processing
    # @param work [Hyrax::Migrator::Work] - the Work model to be processed, including env
    def next(work)
      return true if @next_actor.nil?

      @next_actor.create(work)
    end

    ##
    # Create must be overridden by an actor inheriting this class
    def create(_work)
      raise NotImplementedError, 'An actor class must be able to #create'
    end
  end
end
