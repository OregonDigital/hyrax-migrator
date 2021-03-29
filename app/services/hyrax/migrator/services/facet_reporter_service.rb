# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Create report on facet values for migrated batch of assets
  class FacetReporterService < BatchReporterService
    def initialize(batch_name, config = Hyrax::Migrator.config)
      @batch_name = batch_name
      @migrator_config = config
      @errors = []
      @facet_properties = {}
      @collections = []
      @asset_rows = []
      @report = report(:assets)
    end

    def create_report
      collect_assets
      print_assets
      print_errors
      @report.close
    end

    def collect_assets
      location_service[@batch_name].each do |file_path|
        pid = parse_pid(file_path)
        @asset_rows << asset_report(pid)
      end
    end

    def print_assets
      labels = ['pid']
      labels += @facet_properties.map { |_k, v| v }
      @report.puts labels.join("\t")
      @asset_rows.each do |row|
        @report.puts row
      end
    end

    def asset_report(pid)
      solr_record = Hyrax::Migrator::HyraxCore::Asset.solr_record(pid)
      return log_error(pid) if solr_record.blank?

      add_collections(solr_record)
      record = [pid]
      @facet_properties.keys.each do |key|
        values = solr_record[key].is_a?(Array) ? solr_record[key].join('||') : solr_record[key]
        record << values
      end
      record.join("\t")
    end

    def add_collections(solr_asset)
      return if solr_asset['member_of_collection_ids_ssim'].blank?

      solr_asset['member_of_collection_ids_ssim'].each do |id|
        next if @collections.include? id

        @collections << id
        coll = Hyrax::Migrator::HyraxCore::Asset.find(id)
        merge_properties(coll)
      end
    end

    def merge_properties(coll)
      coll.available_facets.each do |facet|
        @facet_properties[facet.solr_name] = facet.label if @facet_properties[facet.solr_name].blank?
      end
    end

    def log_error(pid)
      @errors << pid
      "#{pid} not found"
    end

    def print_errors
      @report.puts 'assets not found:'
      @errors.each do |pid|
        @report.puts pid
      end
    end

    def report(type)
      puts "File will be written to #{@migrator_config.file_system_path}"
      datetime_today = Time.zone.now.strftime('%Y%m%d%H%M%S') # 20171021125903
      File.open(File.join(@migrator_config.file_system_path, "#{@batch_name}-#{type}-facet_report_#{datetime_today}.txt"), 'w')
    end
  end
end
