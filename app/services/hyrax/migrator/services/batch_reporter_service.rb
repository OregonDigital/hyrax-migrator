# frozen_string_literal:true

module Hyrax::Migrator::Services
  # requires a batch name, iterates through the batch and prints a report either to screen or file
  # optionally provide a migrator config and/or an array of report fields, eg [:verification]
  class BatchReporterService
    def initialize(batch_name, args = {})
      @batch_name = batch_name
      @data_list = args[:data_list] || default_data_list
      @migrator_config = args[:migrator_config] || Hyrax::Migrator.config
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

      line = []
      @data_list.each do |d|
        line << send(d, w).to_s
      end
      line.join("\t")
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

    def headings
      headings = []
      @data_list.each do |d|
        headings << d.to_s
      end
      headings.join("\t")
    end

    def default_data_list
      %i[aasm_state status status_message asset_exists errors]
    end

    def aasm_state(work)
      work.aasm_state || ''
    end

    def status(work)
      work.status || ''
    end

    def status_message(work)
      work.status_message || ''
    end

    def asset_exists(work)
      Hyrax::Migrator::HyraxCore::Asset.exists?(work.pid) || ''
    end

    def errors(work)
      return 'no errors' if work.env[:errors].blank?

      work.env[:errors].join('|')
    end

    def verification(work)
      work.env[:verification_errors] || ''
    end
  end
end
