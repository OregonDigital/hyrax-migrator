# frozen_string_literal:true

require 'aws-sdk-s3'
require 'fileutils'

module Hyrax::Migrator::Services
  # Service used a hash of bags with bag path names and associated bucket
  # directory in an s3 for bags or a directory in the file system
  class BagFileLocationService
    attr_reader :batch_dir_names, :ingest_local_path,
                :aws_s3_app_key, :aws_s3_app_secret, :aws_s3_url_availability,
                :aws_s3_ingest_bucket, :aws_s3_region, :ingest_storage_service

    # @param config [Hyrax::Migrator::Configuration]
    # @param batch_dir_names [String Array]
    def initialize(batch_dir_names, migrator_config)
      @ingest_storage_service = migrator_config.ingest_storage_service
      # batch_dir_names
      @batch_dir_names = batch_dir_names
      # local file system
      @ingest_local_path = migrator_config.ingest_local_path
      # remote aws bucket
      @aws_s3_app_key = migrator_config.aws_s3_app_key
      @aws_s3_app_secret = migrator_config.aws_s3_app_secret
      @aws_s3_ingest_bucket = migrator_config.aws_s3_ingest_bucket
      @aws_s3_region = migrator_config.aws_s3_region
      @aws_s3_url_availability = migrator_config.aws_s3_url_availability
    end

    # returns a hash of locations
    def bags_to_ingest
      if @ingest_storage_service == :aws_s3
        remote_locations
      elsif @ingest_storage_service == :file_system
        local_locations
      end
    end

    private

    def remote_locations
      locations = {}
      batch_dir_names.each do |batch_name|
        locations[batch_name] = remote_bags(batch_name)
      end
      locations
    end

    def remote_bags(batch_name)
      zip_url_bags = []
      aws_s3_objects(batch_name).each do |obj|
        zip_url_bags << obj.presigned_url(:get, expires_in: aws_s3_url_availability) if obj.key.end_with? '.zip'
      end
      zip_url_bags
    end

    def aws_s3_objects(batch_name)
      aws_s3_resource.bucket(aws_s3_ingest_bucket).objects(prefix: batch_name)
    end

    def aws_s3_resource
      Aws::S3::Resource.new(client: aws_s3_client)
    end

    def aws_s3_client
      Aws::S3::Client.new(
        region: aws_s3_region,
        credentials: aws_s3_credentials
      )
    end

    def aws_s3_credentials
      Aws::Credentials.new(@aws_s3_app_key, @aws_s3_app_secret)
    end

    def local_locations
      locations = {}
      batch_locations.map do |b|
        locations[File.basename(b)] = local_bags(b)
      end
      locations
    end

    def local_bags(batch_path)
      bag_zip_files = Dir.entries(batch_path).select { |e| File.file?(File.join(batch_path, e)) && File.extname(e) == '.zip' }
      bag_zip_files.map { |f| File.join(batch_path, f) }
    rescue Errno::ENOENT
      log_and_raise("batch directory #{batch_path} not found")
    end

    def batch_locations
      folders = batch_dir_names.select do |f|
        folder = File.join(ingest_local_path, f)
        File.directory?(folder)
      end
      log_and_raise("could not find any directories with name(s) '#{batch_dir_names.join(',')}' in '#{ingest_local_path}'") unless folders.present?
      folders.map { |f| File.join(ingest_local_path, f) }
    end

    def log_and_raise(message)
      Rails.logger.error(message)
      raise StandardError, message
    end
  end
end
