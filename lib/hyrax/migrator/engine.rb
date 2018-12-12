# frozen_string_literal:true

module Hyrax
  module Migrator
    ##
    # The Rails engine class
    class Engine < ::Rails::Engine
      isolate_namespace Hyrax::Migrator
    end
  end
end
