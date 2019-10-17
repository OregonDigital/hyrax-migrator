# frozen_string_literal:true

module Hyrax::Migrator::Serializers
  # Serialize/deserialize MiddlewareConfiguration so that it can be passed through a MigrateWorkJob to MigrateWorkService
  module MiddlewareConfigurationSerializer
    def self.serialize(configuration)
      arr = []
      configuration.actor_stack.each do |actor|
        arr << actor.to_s
      end
      { actor_stack: arr }
    end

    def self.deserialize(hash)
      Hyrax::Migrator::Configuration.new.actor_stack = actor_stack(hash)
    end

    private

    def actor_stack(hash)
      actor_stack = []
      hash[:actor_stack].each do |actor|
        actor_stack << actor.constantize
      end
      actor_stack
    end
  end
end
