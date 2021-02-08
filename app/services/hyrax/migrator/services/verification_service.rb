# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to compare various elements from the source asset and the migrated asset
  class VerificationService
    def initialize(pid, services, config = Hyrax::Migrator.config)
      @migrated_work = MigratedWork.new(pid, config)
      @services = services
    end

    def verify
      errors = []
      @services.each do |service|
        verifier = service.new(@migrated_work)
        errors << verifier.verify
      end
      @migrated_work.work.remove_temp_directory
      errors
    end

    # Package objects necessary for the verifiers
    class MigratedWork
      attr_reader :work, :asset, :working_directory, :original_profile, :config
      def initialize(pid, config = Hyrax::Migrator.config)
        @work = Hyrax::Migrator::Work.find_by(pid: pid)
        @asset = Hyrax::Migrator::HyraxCore::Asset.find(pid)
        @working_directory = @work.working_directory
        @original_profile = read_original_profile
        @config = config
      end

      def read_original_profile
        YAML.load_file(File.join(@working_directory, "data/#{@work.pid}_profile.yml"))
      end
    end
  end
end
