# frozen_string_literal:true

module Hyrax::Migrator::Services
  # requires a batch name, iterates through the batch and launches a verify work job for each work.
  # at the moment, does not allow custom config to be passed to job
  class BatchVerificationService
    def initialize(batch_name)
      @batch_name = batch_name
    end

    def verify
      location_service[@batch_name].each do |file_path|
        pid = parse_pid(file_path)
        Hyrax::Migrator::Jobs::VerifyWorkJob.perform_later({ pid: pid })
      end
    end

    def location_service
      Hyrax::Migrator::Services::BagFileLocationService.new([@batch_name], Hyrax::Migrator.config).bags_to_ingest
    end

    def parse_pid(file)
      File.basename(file, File.extname(file))
    end
  end
end
