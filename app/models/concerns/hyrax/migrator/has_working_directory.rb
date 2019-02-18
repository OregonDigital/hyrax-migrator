# frozen_string_literal: true

require 'zip'
require 'tmpdir'
require 'fileutils'
require 'aws-sdk-s3'

module Hyrax::Migrator
  # Gives the ability to dynamically create a working directory when the
  # file_path is pointing at a zip file or an S3 url, otherwise returns
  # the original directory set in file_path.
  module HasWorkingDirectory
    extend ActiveSupport::Concern

    def working_directory
      @working_directory ||= build_working_directory
    end

    def remove_temp_directory
      return true if self[:file_path] == working_directory

      # The working directory is not the original file_path, it is expected to
      # be a temporary directory that should be removed.
      FileUtils.rm_rf(working_directory)
      !Dir.exist?(working_directory)
    end

    private

    def build_working_directory
      return handle_remote_file(self[:file_path], self[:pid]) if remote_file?(self[:file_path])

      return extract_local_zip(self[:file_path], self[:pid]) if zip_file?(self[:file_path])

      self[:file_path]
    end

    def remote_file?(file_path)
      file_path.downcase.start_with? 'http'
    end

    def zip_file?(file_path)
      %w[zip gz].include? file_path.split('.').last
    end

    ##
    # Extract the zip file at source_path to a tmpdir for processing. NOTE: The temp directory
    # is created but never removed, this is intented so that any actor can get access to the files
    # during processing. Because these processes are running on emphemeral containers, the temp
    # directory cannot be expected to exist between multiple runs (restarting the process).
    def extract_local_zip(source_path, pid)
      destination_path = temporary_directory(pid)
      Zip::File.open(source_path) do |zipfile|
        zipfile.each do |entry|
          entry.extract(File.join(destination_path, entry.to_s))
        end
      end
      destination_path
    end

    ##
    # Download the file from the URL to a local path and return that path
    # unless it is a zip file in which case also extract the zip file.
    def handle_remote_file(url, pid)
      local_path = download_remote_file(url, pid)
      return local_path unless zip_file?(local_path)

      extracted_local_zip = extract_local_zip(local_path, pid)
      FileUtils.rm_rf(local_path)
      extracted_local_zip
    end

    def download_remote_file(url, pid)
      destination_dir = temporary_directory("#{pid}-download")
      uri = URI.parse(url)
      aws_s3_fetch_object(uri, destination_dir)
    rescue StandardError => e
      FileUtils.rm_rf(destination_dir)
      raise e
    end

    def aws_s3_fetch_object(uri, destination_dir)
      destination_path = File.join(destination_dir, aws_s3_object_filename(uri))
      aws_s3_client.get_object(
        response_target: destination_path,
        bucket: aws_s3_bucket(uri),
        key: aws_s3_object_key(uri)
      )
      destination_path
    end

    def aws_s3_client
      Aws::S3::Client.new(
        region: Hyrax::Migrator.config.aws_s3_region,
        credentials: Aws::Credentials.new(Hyrax::Migrator.config.aws_s3_app_key, Hyrax::Migrator.config.aws_s3_app_secret)
      )
    end

    ##
    # Parse the bucket from the supplied URI
    # uri#path = /bucket/path/to/file.zip
    # split('/') = ['', 'bucket', 'path', 'to', 'file.zip']
    def aws_s3_bucket(uri)
      uri.path.split('/')[1]
    end

    ##
    # Parse the key from the supplied URI
    # uri#path          = /bucket/path/to/file.zip
    # split('/')        = ['', 'bucket', 'path', 'to', 'file.zip']
    # [2..-1].join('/') = 'path/to/file.zip'
    def aws_s3_object_key(uri)
      uri.path.split('/')[2..-1].join('/')
    end

    ##
    # Parse the original filename from the supplied URI
    # uri#path          = /bucket/path/to/file.zip
    # split('/')        = ['', 'bucket', 'path', 'to', 'file.zip']
    def aws_s3_object_filename(uri)
      uri.path.split('/').last
    end

    def temporary_directory(prefix)
      Dir.mktmpdir([prefix, Time.now.to_i.to_s])
    end
  end
end
