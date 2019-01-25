module Hyrax
  module Migrator
    class FileUploadService
      attr_reader :aws_s3_app_key, :aws_s3_app_secret,
                  :aws_s3_bucket, :aws_s3_region,
                  :file_system_path

      # @param file_set_content [File]
      # @param file_system_path [String] 
      # @param aws_s3_app_key [String]
      # @param aws_s3_app_secret [String]
      # @param latest_version_only [String]
      def initialize(file_set_content,
        file_system_path: Hyrax::Migrator.config.file_system_path,
        aws_s3_app_key: Hyrax::Migrator.config.aws_s3_app_key,
        aws_s3_app_secret: Hyrax::Migrator.config.aws_s3_app_secret,
        aws_s3_bucket: Hyrax::Migrator.config.aws_s3_bucket,
        aws_s3_region: Hyrax::Migrator.config.aws_s3_region)

        @file_system_path = file_system_path
        @aws_s3_app_key = aws_s3_app_key
        @aws_s3_app_secret = aws_s3_app_secret
        @aws_s3_bucket = aws_s3_bucket
        @aws_s3_region = aws_s3_region
      end

      def upload_file_content
        #TODO: upload file content to proper storage service
        false
      end
    end
  end
end