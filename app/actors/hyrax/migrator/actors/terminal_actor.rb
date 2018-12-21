# frozen_string_literal: true

module Hyrax
  module Migrator
    module Actors
      # Like Hyrax::Actors::Terminator, place last in actor stack.
      class TerminalActor
        def create(_work)
          true
        end
      end
    end
  end
end
