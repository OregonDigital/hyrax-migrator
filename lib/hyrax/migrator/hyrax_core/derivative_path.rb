# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    # Access the Hyrax DerivativePath model for derivatives verification
    class DerivativePath
      ##
      # This is used in hyrax to access the path on file system where derivative
      # file is stored. We need this to retrieve the available derivatives for
      # the given file set object for verification purposes (QA stage during
      # migration).
      #
      # @see https://github.com/samvera/hyrax/blob/c7ee4e70cb3b9949f3bf91ffb8204780f7cfc869/app/services/hyrax/derivative_path.rb
      def initialize(args)
        @file_set = args[:file_set]
      end

      # Get all derivatives paths available for the given file set object
      # @return ["/data/path1/", "/data/path2", ...] - array, otherwise raise
      # error if any
      def all_paths
        derivatives_for_reference
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
      def derivatives_for_reference
        Hyrax::DerivativePath.derivatives_for_reference(@file_set)
      end
      # :nocov:
    end
  end
end
