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
    end
  end
end
