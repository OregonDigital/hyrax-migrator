# frozen_string_literal: true

module Hyrax::Migrator::Services
  # Called by the FileUploadActor to store checksum values in the env hash
  class LoadFileIdentityService
    def initialize(work_file_path)
      @work_file_path = work_file_path
      @manifest_files = manifest_files
    end

    # Load the manifest files to get the identify hash array for an existing
    # file content.
    #
    # @return an array of hashes containing checksum data, content file name, and
    # checksum encoding
    def content_file_checksums
      @manifest_files.map { |f| identity_hash(f) }
    end

    private

    def identity_hash(file)
      encoding = checksum_algorithm(file)
      data = get_checksum_data(encoding)
      { file_name: File.basename(data[:relative_path]), checksum: data[:checksum], checksum_encoding: encoding } if data.present?
    end

    # Extract the checksum algorithm from a manifest file basename that should come in the form
    # "manifest-{algorithm}.txt"
    #
    def checksum_algorithm(file)
      items = File.basename(file, '.txt').split('-')
      items.last
    end

    def get_checksum_data(encoding)
      case encoding
      when 'sha1'
        read_checksum_data('sha1')
      when 'md5'
        read_checksum_data('md5')
      end
    end

    def read_checksum_data(algo)
      file_algo = @manifest_files.detect { |f| File.basename(f) == "manifest-#{algo}.txt" }
      data = read_manifest(file_algo)
      data.detect { |l| l[:relative_path].include? '_content' } if data.present?
    end

    def read_manifest(file)
      File.open(file).readlines.map { |line| { checksum: line.split(/\s+/).first, relative_path: line.split(/\s+/).last } }
    end

    def manifest_files
      files = Dir.entries(@work_file_path).select do |f|
        file = File.join(@work_file_path, f)
        File.file?(file) && File.basename(file) =~ /^manifest-.*.txt$/
      end
      log_and_raise("could not find the manifest files with pattern manifest-[algorithm].txt in #{@work_file_path}") unless files.present?

      files.map { |f| File.join(@work_file_path, f) }
    rescue Errno::ENOENT
      log_and_raise("data directory #{@work_file_path} not found")
    end

    def log_and_raise(message)
      Rails.logger.error(message)
      raise StandardError, message
    end
  end
end
