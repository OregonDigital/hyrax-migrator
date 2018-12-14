# frozen_string_literal:true

module Hyrax
  module Migrator
    module Middleware
      ##
      # The default middleware for actors processing works through the migrator
      class DefaultMiddleware
        attr_reader :actor_stack

        ##
        # @param [Array[Hyrax::Migrator::AbstractActor]] actors - an array of actors set to process a work
        def initialize(actors)
          @actor_stack ||= build_actor_stack(actors)
        end

        ##
        # Given a work to be processed, the middleware will find the appropriate actor in the stack and
        # begin processing the work. If the work.aasm_state is empty, the first actor in the stack starts the process
        # and calls each nested actor until the chain completes.
        #
        # When work.aasm_state is set, the stack will find the first actor which has the aasm state method that matches
        # and will begin processing from that point to the end.
        #
        # @param [Hyrax::Migrator::Work] work - the work the be migrated
        def start(work)
          actor = find_actor_with_state(work.aasm_state)
          actor.create(work)
        end

        private

        ##
        # Instantiate the first actor as the `head`. Remove the next actor off of the beginning of
        # the actors array, instantiate it and set it as the `next_actor` while recursively iterating through
        # the list until the end. The final actor will have `next_actor` left as nil which indicates that it
        # is the final actor in the stack.
        #
        # @param [Array[Hyrax::Migrator::AbstractActor]] actors - an array of actors set to process a work
        def build_actor_stack(actors)
          return nil if actors.empty?

          head = actors.shift.new
          current_actor = head
          while current_actor.next_actor.nil?
            next_actor = actors.shift
            break if next_actor.nil?

            current_actor.next_actor = next_actor.new
            current_actor = current_actor.next_actor
          end
          head
        end

        ##
        # Dig down the stack to find the first actor to respond_to the method related to
        # the `aasm_state` that was passed to this method. Return the actor that was found
        # which acts as the starting (or restarting) point for the work to be processed.
        #
        # @param [String] aasm_state - the aasm state, like 'bag_validation_failed'
        def find_actor_with_state(aasm_state)
          return @actor_stack if aasm_state.blank?

          state_method = "#{aasm_state}?".to_sym
          current_actor = @actor_stack
          until current_actor.respond_to? state_method
            return current_actor if current_actor.next_actor.nil?

            current_actor = current_actor.next_actor
          end
          current_actor
        end
      end
    end
  end
end
