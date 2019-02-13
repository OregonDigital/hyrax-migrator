# frozen_string_literal:true

module Hyrax::Migrator
  ##
  # The main hyrax migrator configuration!
  class Configuration
    def initialize
      @registered_models = []
    end

    def register_model(*models)
      Array.wrap(models).flatten.compact.each do |m|
        @registered_models << m unless @registered_models.include? m
      end
    end

    def models
      @registered_models
    end

    attr_writer :upload_storage_service
    def upload_storage_service
      @upload_storage_service ||= if Rails.env.staging? || Rails.env.production?
                                    :aws_s3
                                  else
                                    :file_system
                                  end
    end

    attr_writer :file_system_path
    def file_system_path
      @file_system_path ||= ENV['BROWSEEVERYTHING_FILESYSTEM_PATH']
    end

    attr_writer :aws_s3_app_key
    def aws_s3_app_key
      @aws_s3_app_key ||= ENV['AWS_S3_APP_KEY']
    end

    attr_writer :aws_s3_app_secret
    def aws_s3_app_secret
      @aws_s3_app_secret ||= ENV['AWS_S3_APP_SECRET']
    end

    attr_writer :aws_s3_bucket
    def aws_s3_bucket
      @aws_s3_bucket ||= ENV['AWS_S3_BUCKET']
    end

    attr_writer :aws_s3_region
    def aws_s3_region
      @aws_s3_region ||= ENV['AWS_S3_REGION']
    end

    # The time a presigned_url is available after the upload in seconds (defaults to 24 hours).
    attr_writer :aws_s3_url_availability
    def aws_s3_url_availability
      @aws_s3_url_availability ||= 86_400
    end

    # The path to automatically mount the migrator engine to, or setting to false will prevent automatic mounting.
    attr_writer :mount_at
    def mount_at
      @mount_at ||= 'migrator'
    end

    # The background job queue name, defaults to 'hyrax_migrator'
    attr_writer :queue_name
    def queue_name
      @queue_name ||= 'hyrax_migrator'
    end

    # The logger to use for logging
    attr_writer :logger
    def logger
      @logger ||= Logger.new nil
    end

    # The crosswalk metadata file contains the properties and predicates used for transforming the descriptive metadata.
    attr_writer :crosswalk_metadata_file
    def crosswalk_metadata_file
      @crosswalk_metadata_file ||= ''
    end

    attr_writer :crosswalk_overrides_file
    def crosswalk_overrides_file
      @crosswalk_overrides_file ||= ''
    end

    # The crosswalk file for looking up a model related to the metadata type URI for a work.
    # The model should match one that is found in the models configuration for this engine.
    #
    # For example, the following lines in the hyrax_migrator initializer will include
    # reference to the Image and Generic models found in the MyApp::Models namespace
    #
    # config.register_model MyApp::Models::Image
    # config.register_model MyApp::Models::Generic
    attr_writer :model_crosswalk
    def model_crosswalk
      @model_crosswalk ||= ''
    end

    # The users email address who would be shown as having been the depositor of the
    # works being migrated.
    attr_writer :migration_user
    def migration_user
      @migration_user ||= nil
    end
  end
end
