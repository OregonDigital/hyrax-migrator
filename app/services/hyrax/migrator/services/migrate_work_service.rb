# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Called by the MigrateWorkJob
  class MigrateWorkService
    def initialize(args)
      @pid = args[:pid]
      @file_path = args[:file_path]
      @args = args
    end

    def run
      middleware.start(work)
    end

    def work
      @work ||= find_or_create_work(@pid, @file_path)
    end

    def middleware
      @middleware ||= create_middleware
    end

    private

    def find_or_create_work(pid, file_path)
      work = Hyrax::Migrator::Work.where(pid: pid).first
      return work if work

      Hyrax::Migrator::Work.create(pid: pid, file_path: file_path, env: { attributes: { id: pid } })
    end

    def create_middleware
      return Hyrax::Migrator::Middleware.default if @args[:middleware_config].blank?

      Hyrax::Migrator::Middleware.custom(Hyrax::Migrator::Serializers::MiddlewareConfigurationSeralizer.deserialize(@args[:middleware_config]))
    end
  end
end
