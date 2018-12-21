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
    # @!attribute work
    #   @return [Hyrax::Migrator::Work]
    attr_accessor :work

    ##
    # Call the next actor, passing the env along for processing
    def next_actor_for
      return true if @next_actor.nil?

      @next_actor.create(@work)
    end

    ##
    # Create must be overridden by an actor inheriting this class
    # @param work [Hyrax::Migrator::Work] - the Work model to be processed, including env
    # Create must do the assignment @work = work
    def create(_work)
      raise NotImplementedError, 'An actor class must be able to #create'
    end

    ##
    # Add logging
    # @param message [String]
    def log(message)
      Rails.logger.warn "#{@work.pid} #{message}"
    end
  end
end
