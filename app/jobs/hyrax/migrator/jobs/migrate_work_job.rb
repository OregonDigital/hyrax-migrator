# frozen_string_literal: true

module Hyrax
  module Migrator::Jobs
    ##
    # The job responsible for initiating migrating a work
    class MigrateWorkJob < ApplicationJob
      def perform(args)
        service = Hyrax::Migrator::Services::MigrateWorkService.new(args)
        service.run
      end
    end
  end
end
