# frozen_string_literal:true

require 'aws-sdk-s3'
require 'fileutils'

module Hyrax
  module Migrator::Services
    # Service used to upload a given content file to s3 or the file system
    class FileUploadService
      attr_reader :data_dir, :work_file_path, :file_system_path, :aws_s3_app_key,
                  :aws_s3_app_secret, :aws_s3_bucket, :aws_s3_region,
                  :upload_storage_service, :aws_s3_url_availability

      CONTENT_FILE = '_content'

      # @param work_file_path [String]
      # @param migrator_config [Hyrax::Migrator::Configuration]
      def initialize(work_file_path, migrator_config)
        @work_file_path = work_file_path
        @data_dir = File.join(work_file_path, 'data')
        @upload_storage_service = migrator_config.upload_storage_service
        @file_system_path = migrator_config.file_system_path
        @aws_s3_app_key = migrator_config.aws_s3_app_key
        @aws_s3_app_secret = migrator_config.aws_s3_app_secret
        @aws_s3_bucket = migrator_config.aws_s3_bucket
        @aws_s3_region = migrator_config.aws_s3_region
        @aws_s3_url_availability = migrator_config.aws_s3_url_availability
      end

      def upload_file_content
        if @upload_storage_service == :aws_s3
          upload_to_s3
        elsif @upload_storage_service == :file_system
          upload_to_file_system
        end
      end

      private

      # TODO: implement abstract class or refactor this service serving as interface for future storage services like Amazon S3 and others.
      def upload_to_file_system
        content = content_file
        return local_file_obj(nil) unless content.present?

        copy_local_file(content)

        local_file_obj(dest_local_file)
      rescue StandardError => e
        log_and_raise("FileUploadService upload_to_file_system error: #{e.message} : #{e.backtrace}")
      end

      def copy_local_file(content)
        bytes_copied = IO.copy_stream(content, make_path_for(dest_local_file))

        raise StandardError, "Expected #{File.size(dest_local_file)} bytes, received #{bytes_copied} bytes" unless File.size(dest_local_file) == bytes_copied

        ensure_integrity_of(content)
      end

      def ensure_integrity_of(content)
        sha1_checksum = Digest::SHA1.file(content).hexdigest
        md5_checksum = Digest::MD5.file(content).hexdigest

        raise StandardError, 'Content does not match precomputed checksums.' unless sha1_checksum == content_checksum('sha1') && md5_checksum == content_checksum('md5')
      end

      def content_checksum(encoding)
        case encoding
        when 'sha1'
          content_identity_checksums.detect { |c| c[:checksum_encoding] == 'sha1' }.try(:[], :checksum)
        when 'md5'
          content_identity_checksums.detect { |c| c[:checksum_encoding] == 'md5' }.try(:[], :checksum)
        end
      end

      def content_identity_checksums
        Hyrax::Migrator::Services::LoadFileIdentityService.new(@work_file_path).content_file_checksums
      end

      def dest_local_file
        File.join(file_system_path, File.basename(content_file))
      end

      def local_file_obj(filename)
        { 'local_filename' => filename }
      end

      def make_path_for(file)
        file.tap { |path| FileUtils.mkdir_p File.dirname(path) }
      end

      def upload_to_s3
        name = File.basename(content_file)
        obj = aws_s3_resource.bucket(@aws_s3_bucket).object(name)
        return nil unless obj.upload_file(content_file)

        remote_file_obj(obj, name)
      rescue StandardError => e
        log_and_raise("FileUploadService upload_to_s3 error: #{e.message} : #{e.backtrace}")
      end

      def log_and_raise(message)
        Rails.logger.error(message)
        raise StandardError, message
      end

      def remote_file_obj(obj, name)
        { 'url' => obj.presigned_url(:get, expires_in: aws_s3_url_availability), 'file_name' => name }
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

      def log_and_skip(data_dir)
        Rails.logger.warn "could not find a content file in #{data_dir}"
        nil
      end

      def content_file
        files = Dir.entries(@data_dir)
        file = files.find { |f| f.downcase.include?(CONTENT_FILE) }
        return log_and_skip(@data_dir) unless file

        File.join(@data_dir, file)
      rescue Errno::ENOENT
        raise StandardError, "data directory #{@data_dir} not found"
      end
    end
  end
end
