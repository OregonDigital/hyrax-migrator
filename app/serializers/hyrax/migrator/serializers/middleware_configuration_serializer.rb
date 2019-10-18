# frozen_string_literal:true

module Hyrax::Migrator::Serializers
  # Serialize/deserialize MiddlewareConfiguration so that it can be passed through a MigrateWorkJob to MigrateWorkService
  class MiddlewareConfigurationSerializer
    class << self
      def serialize(configuration)
        arr = []
        configuration.actor_stack.each do |actor|
          arr << actor.to_s
        end
        { actor_stack: arr }
      end

      def deserialize(hash)
        config = Hyrax::Migrator::Middleware::Configuration.new
        config.actor_stack = actors(hash)
        config
      end

      private

      def actors(hash)
        arr = []
        hash[:actor_stack].each do |actor|
          arr << actor.constantize
        end
        arr
      end
    end
  end
end
