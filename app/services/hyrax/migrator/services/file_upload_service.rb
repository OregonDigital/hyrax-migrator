require 'aws-sdk-s3'
module Hyrax
  module Migrator::Services
    class FileUploadService
      attr_reader :data_dir, :work_file_path, :file_system_path,
                  :aws_s3_app_key, :aws_s3_app_secret,
                  :aws_s3_bucket, :aws_s3_region, :upload_storage_service

      CONTENT_FILE = '_content'
      AWS_S3_PRESIGNED_GET_URL_VALID = 3600
      # @param work_file_path [String]
      # @param config [Hyrax::Migrator::Configuration]
      def initialize(work_file_path, migrator_config)
        @data_dir = File.join(work_file_path, 'data')
        @upload_storage_service = migrator_config.upload_storage_service
        @file_system_path = migrator_config.file_system_path
        @aws_s3_app_key = migrator_config.aws_s3_app_key
        @aws_s3_app_secret = migrator_config.aws_s3_app_secret
        @aws_s3_bucket = migrator_config.aws_s3_bucket
        @aws_s3_region = migrator_config.aws_s3_region
      end

      def upload_file_content
        if @upload_storage_service == :aws_s3
          upload_to_s3
        elsif @upload_storage_service == :file_system
          upload_to_file_system
        end
      end

      def upload_to_file_system
        name = File.basename(content_file)
        dest_name = File.join(file_system_path, name)
        IO.copy_stream(content_file, dest_name)
      end

      def upload_to_s3
        # Get just the file name
        name = File.basename(content_file)
        # Create the object to upload
        obj = aws_s3_resource.bucket(@aws_s3_bucket).object(name)
        # Upload it      
        return nil unless obj.upload_file(content_file)
        # if upload is successful, return presigned url available for 1 hour
        obj.presigned_url(:get, expires_in: AWS_S3_PRESIGNED_GET_URL_VALID)
      end

      def aws_s3_resource
        Aws::S3::Resource.new(client: aws_s3_client)
      end

      def aws_s3_client
        Aws::S3::Client.new(
          region: aws_s3_region,
          credentials: aws_s3_credentials,
        )
      end

      def aws_s3_credentials
        Aws::Credentials.new(@aws_s3_app_key, @aws_s3_app_secret)
      end

      def content_file
        files = Dir.entries(@data_dir)
        file = files.find { |f| f.downcase.include?(CONTENT_FILE) }
        raise StandardError, "could not find a content file in #{@data_dir}" unless file
        File.join(@data_dir, file)
      rescue Errno::ENOENT
        raise StandardError, "data directory #{@data_dir} not found"
      end
    end
  end
end