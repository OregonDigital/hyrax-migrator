# frozen_string_literal: true

module Hyrax
  module Migrator
    module Actors
      # Like Hyrax::Actors::Terminator, place last in actor stack.
      class TerminalActor
        def create(work)
          work.remove_temp_directory
          true
        end

        def update(work)
          work.remove_temp_directory
          true
        end

        def next_actor
          true
        end
      end
    end
  end
end
