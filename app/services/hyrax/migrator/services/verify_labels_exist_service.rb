# frozen_string_literal:true

module Hyrax::Migrator::Services
  # A service to verify that labels exist using the solr document
  class VerifyLabelsExistService < VerifyService
    def verify
      properties.reject { |p| solr_doc[solrize(p)].blank? }.each do |property|
        count_combined(property)
        verify_labels(property)
      end
      verify_combined
      errs
    end

    def solr_doc
      Hyrax::Migrator::HyraxCore::Asset.solr_record(@migrated_work.asset.id)
    end

    def properties
      Hyrax::Migrator::HyraxCore::Asset.properties.select { |x| x[:is_controlled] == true }.map { |x| x[:name].gsub('_label', '') }
    end

    def solrize(field)
      "#{field}_sim"
    end

    def solrlabelize(field)
      "#{field}_label_sim"
    end

    def combined?(category, field)
      graphworker.send("#{category}_combined_facet?".to_sym, field)
    end

    def graphworker
      @graphworker ||= Hyrax::Migrator::HyraxCore::Asset.fetch_graph_worker
    end

    def verify_labels(property)
      return if solr_doc[solrize(property)].size == solr_doc[solrlabelize(property)].size

      write_err(@migrated_work.asset.id, property, 'fetch labels error')
    rescue StandardError
      write_err(@migrated_work.asset.id, property, 'fetch labels error')
    end

    def combined_labels
      @combined_labels ||= { scientific: Set.new, topic: Set.new, creator: Set.new, location: Set.new }
    end

    def count_combined(field)
      combined_labels.keys.select { |key| combined?(key, field.to_sym) }.each do |key|
        combined_labels[key].merge solr_doc["#{field}_label_sim"] unless solr_doc["#{field}_label_sim"].blank?
      end
    end

    def verify_combined
      combined_labels.reject { |_key, val| val.empty? }.each do |key, val|
        next if val.subset? solr_doc["#{key}_combined_label_sim"].to_set

        write_err(@migrated_work.asset.id, key, 'combined_label error')
      rescue StandardError
        write_err(@migrated_work.asset.id, key, 'combined_label error')
      end
    end

    def write_err(pid, property, msg)
      errs << "#{msg}: #{pid}, #{property}"
    end

    def errs
      @errs ||= []
    end
  end
end
