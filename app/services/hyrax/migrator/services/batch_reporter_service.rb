# frozen_string_literal:true

module Hyrax::Migrator::Services
  # requires a batch name, iterates through the batch and prints a report either to screen or file
  class BatchReporterService
    def initialize(batch_name, migrator_config = Hyrax::Migrator.config)
      @batch_name = batch_name
      @migrator_config = migrator_config
    end

    def write_report
      puts "File will be written to #{@migrator_config.file_system_path}"
      datetime_today = Time.zone.now.strftime('%Y%m%d%H%M%S') # "20171021125903"
      f = File.open(File.join(@migrator_config.file_system_path, "#{@batch_name}_report_#{datetime_today}.txt"), 'w')
      f.puts headings
      print { |m| f.puts "#{m}\n" }
      f.close
    end

    def screen_report
      report = "Printing #{headings} for batch #{@batch_name} *****************************\n"
      print { |m| report += "#{m}\n" }
      puts report
    end

    def asset_report(pid)
      w = Hyrax::Migrator::Work.find_by(pid: pid)
      return 'migrator work not found' if w.nil?

      exists = Hyrax::Migrator::HyraxCore::Asset.exists?(pid)
      "#{w.aasm_state}\t#{w.status}\t#{w.status_message}\t#{errors(w)}\t#{exists}"
    end

    def location_service
      Hyrax::Migrator::Services::BagFileLocationService.new([@batch_name], @migrator_config).bags_to_ingest
    end

    def parse_pid(file)
      File.basename(file, File.extname(file))
    end

    def print
      location_service[@batch_name].each do |file_path|
        pid = parse_pid(file_path)
        yield "#{pid}: #{asset_report(pid)}"
      end
    end

    def errors(work)
      return 'no errors' if work.env[:errors].blank?

      work.env[:errors].join('|')
    end

    def headings
      'aasm_state, status, status_message, errors, asset.exists?'
    end
  end
end
