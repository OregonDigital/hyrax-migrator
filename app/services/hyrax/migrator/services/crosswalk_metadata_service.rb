# frozen_string_literal:true

require 'rdf'
require 'rdf/ntriples'
require 'uri'

module Hyrax::Migrator::Services
  # Called by the CrosswalkMetadataActor to map OD1 metadata to OD2
  class CrosswalkMetadataService
    def initialize(work, migrator_config)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
      @config = migrator_config
      @skip_field_mode = migrator_config.skip_field_mode
      @errors = []
    end

    # returns result hash
    def crosswalk
      graph = create_graph
      graph.statements.each do |statement|
        data = lookup(statement.predicate.to_s)
        next if data.nil?

        processed_obj = process(data, statement.object)
        next if processed_obj.nil?

        assemble_hash(data, processed_obj)
      end
      @result[:errors] = @errors unless @errors.empty? || @result.blank?
      @result
    end

    private

    # Load the nt file and return graph
    def create_graph
      Hyrax::Migrator::Services::CreateGraphService.call(@data_dir)
    end

    # Given property data and an object, adds them to result hash
    def assemble_hash(data, object)
      return if data[:property].blank?

      @result ||= {}
      if data[:multiple]
        @result[data[:property].to_sym] ||= []
        @result[data[:property].to_sym] += [object]
      else
        @result[data[:property].to_sym] = object
      end
    end

    def find(predicate)
      proc { |k| k[:predicate].casecmp(predicate).zero? }
    end

    # Given an OD2 predicate, returns associated property data or nil
    def lookup(predicate)
      hash = crosswalk_hash
      result = hash.select(&find(predicate))
      return result.first unless result.empty?

      if @skip_field_mode
        @errors << "Predicate not found: #{predicate} during crosswalk for #{@work.pid}"
        return nil
      end
      raise PredicateNotFoundError, predicate
    end

    # Given property data and an OD1 object, returns either the object, or a modified object
    def process(data, object)
      data[:function].blank? ? object.to_s : send(data[:function].to_sym, object.to_s)
    end

    # Returns a hash that maps OD2 predicates to OD2 properties and other data needed to process each field.
    def crosswalk_hash
      unique = crosswalk_data.reject { |x| crosswalk_overrides.one?(&find(x[:predicate])) }
      @crosswalk_hash ||= crosswalk_overrides + unique
    end

    def crosswalk_data
      @crosswalk_data ||= YAML.load_file(@config.crosswalk_metadata_file).deep_symbolize_keys
      @crosswalk_data[:crosswalk]
    end

    def crosswalk_overrides
      @crosswalk_overrides ||= YAML.load_file(@config.crosswalk_overrides_file).deep_symbolize_keys
      @crosswalk_overrides[:overrides]
    end

    def return_nil(_object)
      nil
    end

    ##
    # Generate the data necessary for a Rails nested attribute
    def attributes_data(object)
      return { 'id' => object.to_s, '_destroy' => 0 } unless valid_uri(object.to_s).nil?

      @errors << "Invalid URI #{object} found in crosswalk of #{@work.pid}"
      return nil if @skip_field_mode

      raise URI::InvalidURIError, object.to_s
    end

    ##
    # Return datetime object from date string. Acceptable formats:
    # mm/dd/yyyy, and yyyy-mm-dd. Return original if not valid.
    #
    # Examples:
    #
    # datetime_data("10/28/2014")
    #   => Tue, 28 Oct 2014 00:00:00 +0000
    # datetime_data("2014-10-28")
    #   => Tue, 28 Oct 2014 00:00:00 +0000
    def datetime_data(object)
      return object unless object.present?

      DateTime.strptime(object, '%Y-%m-%d').to_s
    rescue ArgumentError => e
      rescue_and_retry_datetime(object, e)
    end

    # This method tries parsing the date with additional formats
    def rescue_and_retry_datetime(object, error)
      raise DateTimeDataError, object unless error.message == 'invalid date'

      DateTime.strptime(object, '%m/%d/%Y').to_s
    rescue ArgumentError
      raise DateTimeDataError, object
    end

    ##
    # Temporary modification to rights rr-f
    # related issue https://github.com/OregonDigital/hyrax-migrator/issues/70
    # TODO: This method can be removed once remediation rr-f is done
    # :nocov:
    def attributes_replaces_data(object)
      old_uri = 'http://opaquenamespace.org/ns/rights/rr-f'
      find_new_uri = replaces_uris.select { |u| u[:old_uri] == old_uri }
      new_uri = find_new_uri.first[:new_uri] if find_new_uri.present?

      return new_uri if object.to_s == old_uri

      return object.to_s unless valid_uri(object.to_s).nil?
    end

    def replaces_uris
      [{ old_uri: 'http://opaquenamespace.org/ns/rights/rr-f', new_uri: 'http://rightsstatements.org/vocab/InC/1.0/' }]
    end
    # :nocov:

    def valid_uri(uri)
      uri =~ URI.regexp(%w[http https])
    end

    # Raise in datetime_data when error found or format is unsupported
    class DateTimeDataError < StandardError
    end

    # Raise in lookup
    class PredicateNotFoundError < StandardError
    end

    # Use in object modifying functions, identify object in message
    class ModifyObjectFailedError < StandardError
    end
  end
end
