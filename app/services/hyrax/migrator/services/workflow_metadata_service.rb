# frozen_string_literal: true
require 'byebug'

module Hyrax::Migrator::Services
  # Called by the WorkflowMetadataActor to retrieve additional data from WorkflowMetadata
  class WorkflowMetadataService
    attr_reader :result
    def initialize(work)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
    end

    def workflow_metadata_profile
      @result ||= YAML.load_file(File.join(@data_dir, "#{@work.pid}_workflowMetadata_profile.yml"))
      @result
    rescue Errno::ENOENT
      message = "workflowMetadata_profile for #{@work.pid} not found"
      Rails.logger.error(message)
      raise StandardError, message
    end
  end
end
