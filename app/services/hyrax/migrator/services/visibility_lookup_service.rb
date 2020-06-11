# frozen_string_literal:true

require 'nokogiri'

module Hyrax::Migrator::Services
  ##
  # A service to inspect the metadata and crosswalk the type to a model used for migration
  class VisibilityLookupService
    XML_NODE = 'group'
    XML_FILE = 'rightsmetadata.xml'

    def initialize(work, migrator_config)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
      @config = migrator_config
    end

    def lookup_visibility
      result = lookup(read_groups)
      return result if comparison_check(result)

      raise StandardError, 'visibility does not agree with access_restrictions'
    end

    private

    def doc
      File.open(xml_file) { |f| Nokogiri::XML(f) }
    rescue Errno::ENOENT
      raise StandardError, "could not find xml file #{xml_file} in #{@data_dir}"
    end

    def xml_file
      files = Dir.entries(@data_dir)
      file = files.find { |f| f.downcase.end_with?(XML_FILE) }
      raise StandardError, "could not find an xml file ending with '#{XML_FILE}' in #{@data_dir}" unless file

      File.join(@data_dir, file)
    rescue Errno::ENOENT
      raise StandardError, "data directory #{@data_dir} not found"
    end

    def read_groups
      nodes = doc.search(XML_NODE)
      raise StandardError, "could not find #{XML_NODE} in xml file" if nodes.empty?

      nodes.map(&:text)
    end

    def lookup(groups)
      if groups.include? 'public'
        { visibility: 'open' }
      elsif (groups.include? 'University-of-Oregon') || (groups.include? 'Oregon-State')
        { visibility: 'authenticated' }
      else
        { visibility: 'restricted' }
      end
    end

    def comparison_check(visibility)
      unless @work[:env][:attributes][:access_restrictions_attributes].blank?
        return true if visibility[:visibility] == 'authenticated'

        return false
      end
      true
    end
  end
end
