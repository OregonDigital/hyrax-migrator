# frozen_string_literal:true

module Hyrax
  module Migrator
    module Middleware
      ##
      # Configurations for the middleware
      class Configuration
        ##
        # The list of actors which need to process a work through
        # migration in the order provided. If there is no intializer
        # set, the default is provided.
        attr_writer :actor_stack
        def actor_stack
          @actor_stack ||= []
        end
      end
    end
  end
end
