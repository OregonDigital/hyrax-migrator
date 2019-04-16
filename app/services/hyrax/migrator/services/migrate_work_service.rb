# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Called by the MigrateWorkJob
  class MigrateWorkService
    def initialize(args)
      @pid = args[:pid]
      @file_path = args[:file_path]
    end

    def run
      middleware.start(work)
    end

    def work
      @work ||= find_or_create_work(@pid, @file_path)
    end

    def middleware
      @middleware ||= Hyrax::Migrator::Middleware.default
    end

    private

    def find_or_create_work(pid, file_path)
      work = Hyrax::Migrator::Work.where(pid: pid).first
      return work if work

      Hyrax::Migrator::Work.create(pid: pid, file_path: file_path)
    end
  end
end
