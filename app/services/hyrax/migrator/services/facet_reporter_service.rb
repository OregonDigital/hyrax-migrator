# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Create report on facet values for migrated batch of assets
  class FacetReporterService < BatchReporterService
    def initialize(batch_name, collection_id, config = Hyrax::Migrator.config)
      @batch_name = batch_name
      @collection_id = collection_id
      @migrator_config = config
      @errors = []
      @facet_properties = {}
      @collections = []
      @asset_rows = []
      @report1 = report(:assets)
      @report2 = report(:totals)
    end

    def create_report
      collect_assets
      print_assets
      print_totals
      print_errors
      @report1.close
      @report2.close
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
      @report1.puts labels.join("\t")
      @asset_rows.each do |row|
        @report1.puts row
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

    def print_totals
      properties.each do |property|
        results = search_service.search(@collection_id, property)
        rows = format_facet_total(results['facet_counts']['facet_fields'])
        rows.each do |row|
          @report2.puts row
        end
      end
    end

    def format_facet_total(facet_hash)
      rows = []
      facet_hash.values.first.each_slice(2) do |s|
        puts "#{facet_hash.keys.first}\t#{s[0]}\t#{s[1]}"
      end
      rows
    end

    def search_service
      @search_service ||= Hyrax::Migrator::HyraxCore::SearchService.new
    end

    def properties
      Hyrax::Migrator::HyraxCore::Asset.find(@collection_id).available_facets.map(&:solr_name)
    end

    def log_error(pid)
      @errors << pid
      "#{pid} not found"
    end

    def print_errors
      @report2.puts 'assets not found:'
      @errors.each do |pid|
        @report2.puts pid
      end
    end

    def report(type)
      puts "File will be written to #{@migrator_config.file_system_path}"
      datetime_today = Time.zone.now.strftime('%Y%m%d%H%M%S') # 20171021125903
      File.open(File.join(@migrator_config.file_system_path, "#{@batch_name}-#{type}-facet_report_#{datetime_today}.txt"), 'w')
    end
  end
end
