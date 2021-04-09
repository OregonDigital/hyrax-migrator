# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Called by the VerifyWorkJob
  # Runs the verification suite and adds any returned errors to the migrator work
  class VerifyWorkService
    def initialize(args)
      @pid = args[:pid]
    end

    def run
      vs = Hyrax::Migrator::Services::VerificationService.new(work, Hyrax::Migrator.config)
      errors = vs.verify
      return if errors.blank?

      work.env[:verification_errors] = errors
      work.save
    end

    def work
      @work ||= Hyrax::Migrator::Work.find_by(pid: @pid)
    end
  end
end
