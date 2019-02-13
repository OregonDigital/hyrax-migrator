# frozen_string_literal:true

require 'aasm'

module Hyrax::Migrator::Actors
  ##
  # Abstract class that actors should inherit from
  class AbstractActor
    include AASM

    def config
      Hyrax::Migrator.config
    end

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
    def call_next_actor
      return true if @next_actor.nil?
      raise StandardError, "#{self.class} missing @work, try calling super in #create or set the variable directly." unless @work

      @next_actor.create(@work)
    end

    ##
    # Create must be overridden by an actor inheriting this class
    # @param work [Hyrax::Migrator::Work] - the Work model to be processed, including env
    def create(work)
      @work = work
    end

    ##
    # Add logging
    # @param message [String]
    def log(message)
      Rails.logger.warn "#{@work.pid} #{message}"
    end

    def failed(aasm_state, message, status)
      update_work(aasm_state, message, status)
    end

    def succeeded(aasm_state, message, status)
      update_work(aasm_state, message, status)
      call_next_actor
    end

    def update_work(aasm_state, message = nil, status = nil)
      @work.status_message = message
      @work.status = status
      @work.aasm_state = aasm_state
      @work.save
    end
  end
end
