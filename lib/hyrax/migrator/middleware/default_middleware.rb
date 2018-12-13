# frozen_string_literal:true

module Hyrax
  module Migrator
    module Middleware
      ##
      # The default middleware for actors processing works through the migrator
      class DefaultMiddleware
        def initialize(actor_stack)
          puts actor_stack
        end
      end
    end
  end
end
