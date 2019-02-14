# frozen_string_literal: true

require 'zip'
require 'tmpdir'
require 'fileutils'

module Hyrax::Migrator
  # A work represents the bag
  class Work < ApplicationRecord
    SUCCESS = 'success'
    FAIL = 'fail'

    serialize :env, Hash

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
      # TODO: Consider if file_path could be an S3 url, fetch url before handling it?
      return extract_zip(self[:file_path], self[:pid]) if %w[zip gz].include?(self[:file_path].split('.').last)

      self[:file_path]
    end

    ##
    # Extract the zip file at source_path to a tmpdir for processing. NOTE: The temp directory
    # is created but never removed, this is intented so that any actor can get access to the files
    # during processing. Because these processes are running on emphemeral containers, the temp
    # directory cannot be expected to exist between multiple runs (restarting the process).
    def extract_zip(source_path, pid)
      destination_path = Dir.mktmpdir([pid, Time.now.to_i.to_s])
      Zip::File.open(source_path) do |zipfile|
        zipfile.each do |entry|
          entry.extract(File.join(destination_path, entry.to_s))
        end
      end
      destination_path
    end
  end
end
