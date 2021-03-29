# frozen_string_literal:true

module Hyrax::Migrator::Services
  # Create report on facet values for migrated batch of assets
  class FacetTotalsReporterService
    def initialize(collection_id, config = Hyrax::Migrator.config)
      @collection_id = collection_id
      @migrator_config = config
      @report = report(:totals)
    end

    def create_report
      print_totals
      @report.close
    end

    def print_totals
      properties.each do |property|
        results = search_service.search(@collection_id, property)
        rows = format_facet_total(results['facet_counts']['facet_fields'])
        rows.each do |row|
          @report.puts row
        end
      end
    end

    def format_facet_total(facet_hash)
      rows = []
      facet_hash.values.first.each_slice(2) do |s|
        rows << "#{facet_hash.keys.first}\t#{s[0]}\t#{s[1]}"
      end
      rows
    end

    def search_service
      @search_service ||= Hyrax::Migrator::HyraxCore::SearchService.new
    end

    def properties
      Hyrax::Migrator::HyraxCore::Asset.find(@collection_id).available_facets.map(&:solr_name)
    end

    def report(type)
      puts "File will be written to #{@migrator_config.file_system_path}"
      datetime_today = Time.zone.now.strftime('%Y%m%d%H%M%S') # 20171021125903
      File.open(File.join(@migrator_config.file_system_path, "#{@collection_id}-#{type}-facet_report_#{datetime_today}.txt"), 'w')
    end
  end
end
