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
      Hyrax::Migrator::HyraxCore::Asset.solr_record(@migrated_work.pid)
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

      write_err(@migrated_work.pid, property, 'fetch labels error')
    rescue StandardError
      write_err(@migrated_work.pid, property, 'fetch labels error')
    end

    def combined_labels
      @combined_labels ||= { scientific: 0, topic: 0, creator: 0, location: 0 }
    end

    def count_combined(field)
      count = solr_doc["#{field}_sim"].size
      combined_labels.each do |key, _val|
        combined_labels[key] += count if combined?(key, field.to_sym)
      end
    end

    def verify_combined
      combined_labels.select { |_key, val| val.positive? }.each do |key, val|
        next if val == solr_doc["#{key}_combined_label_sim"].size

        write_err(@migrated_work.pid, key, 'combined_label error')
      rescue StandardError
        write_err(@migrated_work.pid, key, 'combined_label error')
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
