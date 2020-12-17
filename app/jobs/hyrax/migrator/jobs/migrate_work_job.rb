# frozen_string_literal: true

module Hyrax
  module Migrator::Jobs
    ##
    # The job responsible for initiating migrating a work
    class MigrateWorkJob < Hyrax::Migrator::ApplicationJob
      around_perform do |job, block|
        Rails.logger.info "Starting main migration job #{job.arguments.first[:pid]}"
        block.call
        Rails.logger.info "Finishing main migration job #{job.arguments.first[:pid]}"
      end

      def perform(args)
        service = Hyrax::Migrator::Services::MigrateWorkService.new(args)
        service.run
      end
    end
  end
end
