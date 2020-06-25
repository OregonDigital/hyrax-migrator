# frozen_string_literal: true

require 'byebug'

module Hyrax::Migrator::Services
  # Called by the WorkflowMetadataActor to retrieve additional data from WorkflowMetadata and update asset
  # to set new expected values, i.e. date_uploaded
  class WorkflowMetadataService
    attr_reader :result
    def initialize(work)
      @work = work
      @data_dir = File.join(work.working_directory, 'data')
    end

    def update_asset
      asset.date_uploaded = profile_lookup[:date_uploaded].to_datetime
      status = @asset.save!
      status
    rescue StandardError => e
      message = "failed to update date_uploaded on work #{@work.pid}, #{e.message} #{e.backtrace}"
      Rails.logger.error message
      raise StandardError, message
    end

    def profile_lookup
      result_hash = {}
      metadata_profile_map.each do |field, profile_field|
        result_hash[field] = workflow_profile[profile_field]
      end
      result_hash
    end

    def workflow_profile
      @result ||= YAML.load_file(File.join(@data_dir, "#{@work.pid}_workflowMetadata_profile.yml"))
      @result
    rescue Errno::ENOENT
      message = "workflowMetadata_profile for #{@work.pid} not found"
      Rails.logger.error(message)
      raise StandardError, message
    end

    def asset
      @asset ||= Hyrax::Migrator::HyraxCore::Asset.find(@work.pid)
      @asset
    end

    def metadata_profile_map
      { date_uploaded: 'dsCreateDate' }
    end
  end
end
