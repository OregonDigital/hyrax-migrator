# frozen_string_literal:true

module Hyrax
  module Migrator
    module Middleware
      ##
      # The default middleware for actors processing works through the migrator
      class DefaultMiddleware
        attr_reader :actor_stack

        def initialize(actors)
          @actor_stack ||= build_actor_stack(actors)
        end

        def start(aasm_state = nil)
          # If aasm_state is nil, then
        end

        private

        def build_actor_stack(actors)
          actors.map.with_index do |actor, i|
            next_actor = actors[i + 1] || nil
            actor.new(next_actor)
          end
        end
      end
    end
  end
end
