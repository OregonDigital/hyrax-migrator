# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Service used a hash of bags with bag path names and associated bucket
  # directory in an s3 for bags or a directory in the file system
  class BagIngestService
    attr_reader :migrator_config, :location_service, :input_batch_names

    # @param batch_dir_names [String Array] or single name
    # @param options hash for passing args to the MigrateWorkService
    def initialize(input_batch_names, options = nil)
      @options = options
      @migrator_config = set_config
      @input_batch_names = input_batch_names.is_a?(Array) ? input_batch_names : [input_batch_names]
      @location_service = bag_file_location_service
    end

    def ingest
      # run job for each bag within batch_name
      location_service.bags_to_ingest.each do |_batch_name, bag_locations|
        bag_locations.each do |file_path|
          pid = parse_pid(file_path)
          if Hyrax::Migrator::HyraxCore::Asset.exists?(pid) && migrator_success?(pid)
            Rails.logger.warn "Work #{pid} already exists, skipping MigrateWorkJob"
            next
          end
          Hyrax::Migrator::Jobs::MigrateWorkJob.perform_later(args(pid, file_path))
        end
      end
    end

    private

    def set_config
      return Hyrax::Migrator.config if @options.nil?

      @migrator_config = @options.include?(:migrator_config) ? @options.delete(:migrator_config) : Hyrax::Migrator.config
    end

    def args(pid, file_path)
      args = { pid: pid, file_path: file_path }
      args.merge! @options unless @options.nil?
      args
    end

    def migrator_success?(pid)
      Hyrax::Migrator::Work.find_by(pid: pid, status: Hyrax::Migrator::Work::SUCCESS).present?
    end

    def parse_pid(file)
      File.basename(file, File.extname(file))
    end

    def bag_file_location_service
      Hyrax::Migrator::Services::BagFileLocationService.new(input_batch_names, migrator_config)
    end
  end
end
