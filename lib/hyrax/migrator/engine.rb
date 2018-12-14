# frozen_string_literal:true

module Hyrax
  module Migrator
    ##
    # The Rails engine class
    class Engine < ::Rails::Engine
      isolate_namespace Hyrax::Migrator

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: 'spec/factories'
      end

      config.after_initialize do |app|
        if Hyrax::Migrator.config.mount_at
          Hyrax::Migrator.config.logger.info("after_initialize, mounting hyrax-migrator at '/#{Hyrax::Migrator.config.mount_at}'")
          app.routes.prepend do
            mount Hyrax::Migrator::Engine => Hyrax::Migrator.config.mount_at, as: "migrator"
          end
        end
      end
    end
  end
end
