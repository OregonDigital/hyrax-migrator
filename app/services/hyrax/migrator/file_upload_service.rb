module Hyrax
  module Migrator
    class FileUploadService
      attr_reader :work, :file_system_path,
                  :aws_s3_app_key, :aws_s3_app_secret,
                  :aws_s3_bucket, :aws_s3_region

      # @param work [Work]
      # @param file_system_path [String] 
      # @param aws_s3_app_key [String]
      # @param aws_s3_app_secret [String]
      # @param latest_version_only [String]
      def initialize(work, config)
        @work = work
        @file_system_path = config.file_system_path
        @aws_s3_app_key = config.aws_s3_app_key
        @aws_s3_app_secret = config.aws_s3_app_secret
        @aws_s3_bucket = config.aws_s3_bucket
        @aws_s3_region = config.aws_s3_region
      end

      def upload_file_content
        #TODO: upload file content to proper storage place using active storage
        false
      end
    end
  end
end