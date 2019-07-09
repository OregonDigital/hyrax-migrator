# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Service used a hash of bags with bag path names and associated bucket
  # directory in an s3 for bags or a directory in the file system
  class BagIngestService
    attr_reader :migrator_config, :location_service, :input_batch_names

    # @param batch_dir_names [String Array]
    # @param config [Hyrax::Migrator::Configuration]
    def initialize(input_batch_names, migrator_config)
      @migrator_config = migrator_config
      @input_batch_names = input_batch_names
      @location_service = bag_file_location_service
    end

    def ingest
      # run job for each bag within batch_name
      location_service.bags_to_ingest.each do |_batch_name, bag_locations|
        bag_locations.each do |file_path|
          pid = parse_pid(file_path)
          Hyrax::Migrator::Jobs::MigrateWorkJob.perform_later(pid: pid, file_path: file_path)
        end
      end
    end

    private

    def parse_pid(file)
      File.basename(file, File.extname(file))
    end

    def bag_file_location_service
      Hyrax::Migrator::Services::BagFileLocationService.new(input_batch_names, config: migrator_config)
    end
  end
end
