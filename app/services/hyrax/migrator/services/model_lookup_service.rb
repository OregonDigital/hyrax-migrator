# frozen_string_literal:true

require 'nokogiri'

module Hyrax::Migrator::Services
  ##
  # A service to inspect the metadata and crosswalk the type to a model used for migration
  class ModelLookupService
    XML_NODE_XPATH = '//rdf:RDF/rdf:Description/ns0:hasModel'
    XML_FILE = 'rels-ext.xml'

    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
      crosswalk
    end

    ##
    # Using the configured crosswalk for model lookup, and the migrator engine configuration,
    # determine what model to use for this work and if the model is registered to the engine
    # through the initializer. This model name will eventually be used to build a new instance
    # set the attributes, collection membership, and associate uploaded files before calling
    # #save on it to persist to the Hyrax application.
    #
    # returns [String] the model name found in the model_crosswalk so long as its a registered model in the engine
    def model
      node_value = at_node(doc)
      lookup_model(node_value)
    end

    private

    def crosswalk
      @crosswalk ||= YAML.load_file(@config.model_crosswalk)
    rescue Errno::ENOENT
      raise StandardError, "could not find model lookup configuration at #{@config.model_crosswalk}"
    end

    def doc
      File.open(xml_file) { |f| Nokogiri::XML(f) }
    rescue Errno::ENOENT
      raise StandardError, "could not find xml file #{xml_file} in #{@work.bag.data_dir}"
    end

    def xml_file
      files = @work.bag.bag_files
      file = files.find { |f| f.downcase.end_with?(XML_FILE) }
      raise StandardError, "could not find an xml file ending with '#{XML_FILE}' in #{@work.bag.data_dir}" unless file

      file
    end

    def at_node(doc)
      node = doc.xpath(XML_NODE_XPATH)
      raise StandardError, "could not find #{XML_NODE_XPATH} in xml file" if node.empty?

      node.first.attributes['resource'].value
    end

    def lookup_model(node_value)
      model = crosswalk[node_value]
      raise StandardError, "could not find a configuration for #{node_value} in #{@config.model_crosswalk}" unless model

      message = "#{model} not a registered model in the migrator initializer"
      raise StandardError, message unless @config.models.include?(model)

      model
    end
  end
end
