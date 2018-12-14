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
    attr_accessor :next_actor

    ##
    # Call the next actor, passing the env along for processing
    # @param work [Hyrax::Migrator::Work] - the Work model to be processed, including env
    def next_actor_for(work)
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
