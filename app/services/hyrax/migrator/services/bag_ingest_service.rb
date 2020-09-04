# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Service used a hash of bags with bag path names and associated bucket
  # directory in an s3 for bags or a directory in the file system
  class BagIngestService
    attr_reader :migrator_config, :location_service, :input_batch_names

    # @param batch_dir_names [String Array]
    # @param config [Hyrax::Migrator::Configuration]
    # @param options hash for passing args to the MigrateWorkService
    def initialize(input_batch_names, migrator_config, options = nil)
      @migrator_config = migrator_config
      @input_batch_names = input_batch_names
      @location_service = bag_file_location_service
      @options = options
      @pids = harvest_pids
    end

    def ingest
      # run job for each bag within batch_name
      @pids.each do |batch_name|
        @pids[batch_name|.each do |pid|
        if Hyrax::Migrator::HyraxCore::Asset.exists?(pid) && migrator_success?(pid)
          Rails.logger.warn "Work #{pid} already exists, skipping MigrateWorkJob"
          next
        end
        Hyrax::Migrator::Jobs::MigrateWorkJob.perform_later(args(pid, file_path))
      end
    end

    def batch_report(batch_name, to_file=false)
      report = {}
      @pids[batch_name].each do |pid|
        w = Hyrax::Migrator::Work.find_by_pid(pid)
        asset = Hyrax::Migrator::HyraxCore::Asset.exists?(pid)
        report[pid] = "#{w.aasm_state}\t#{w.status}\t#{w.status_message}\t#{asset}" unless w.nil?
        next

        report[pid] = "migrator work not found"
      end
      to_file ? write_to_file(batch_name, report) : write_to_screen(report)
    end

    private

    def write_to_screen(report)
      puts "Printing aasm_state, status, status_message, and asset.exists? for works in batch #{batch_name}..."
      report.each do |pid, val|
        puts "#{pid}: #{val}"
      end
    end

    def write_to_file(batch_name, report)
      puts "Printing aasm_state, status, status_message, and asset.exists? for works in batch #{batch_name}."
      puts "File will be written to #{migrator_config.file_system_path}"
      datetime_today = Time.zone.now.strftime('%Y%m%d%H%M%S') # "20171021125903"
      f = File.open(File.join(migrator_config.file_system_path, "#{batch_name}_report_#{datetime_today}.txt", 'w')
      report.each do |pid, val|
        f.puts "#{pid}: #{val}"
      end
      f.close
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

    def harvest_pids
      pid_hash = {}
      location_service.bags_to_ingest.each do |_batch_name, bag_locations|
        pid_hash[_batch_name] = []
        bag_locations.each do |file_path|
          pid_hash[_batch_name] << parse_pid(file_path)
        end
      end
      pid_hash
    end
  end
end
