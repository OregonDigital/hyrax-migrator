# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Called by the VerifyWorkJob
  # Runs the verification suite and adds any returned errors to the migrator work
  class VerifyWorkService
    def initialize(args)
      @args = args
      @services = services
    end

    def run
      vs = Hyrax::Migrator::Services::VerificationService.new(@args[:pid], @services)
      work.env[:verification_errors] = vs.verify
      work.save
    end

    def work
      @work ||= Hyrax::Migrator::Work.find_by(pid: @args[:pid])
    end

    # allow a different list of services to be used on the fly
    def services
      return Hyrax::Migrator.config.verify_services if @args[:verify_services].blank?

      services = []
      @args[:verify_services].each do |s|
        services << s.constantize
      end
      services
    end
  end
end
