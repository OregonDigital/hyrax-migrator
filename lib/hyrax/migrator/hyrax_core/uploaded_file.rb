# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    # Access the Hyrax UploadedFile model work file uploads
    class UploadedFile
      ##
      # This is used in hyrax to store a file uploaded by a user. Hyrax uses these records to
      # attach them to FileSets when a work is created. We need access to this model
      # so that we can prepare these records during migration.
      #
      # @see https://github.com/samvera/hyrax/blob/master/app/models/hyrax/uploaded_file.rb
      def initialize(args)
        @user = args[:user]
        @uploaded_file_uri = args[:uploaded_file_uri]
        @uploaded_filename = args[:uploaded_filename]
      end

      # Create Hyrax::UploadedFile record
      # @return [Hyrax::UploadedFile] - object if create was successful, otherwise raise error
      def create
        create_uploaded_file
      rescue StandardError => e
        logger.error(e.message)
        raise e
      end

      private

      def logger
        @logger ||= Rails.logger
      end

      ## No coverage for Hyrax application integration to eliminate dependencies
      # :nocov:
      def create_uploaded_file
        Hyrax::UploadedFile.create(user: @user, file_set_uri: @uploaded_file_uri, file: local_file)
      end

      def local_file
        @local_file = File.open(@uploaded_filename)
      end
      # :nocov:
    end
  end
end
