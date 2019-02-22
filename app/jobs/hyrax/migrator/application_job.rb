# frozen_string_literal: true

module Hyrax
  module Migrator
    ##
    # The base ActiveJob class for the application
    class ApplicationJob < ActiveJob::Base
      queue_as Hyrax::Migrator.config.queue_name
    end
  end
end
