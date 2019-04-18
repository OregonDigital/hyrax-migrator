# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    # Access the Hyrax AdminSet model
    class AdminSet
      ##
      # This model is used in hyrax to manage AdminSets. We need access to
      # AdminSet to lookup the proper admin set id required during
      # migration.
      #
      # @see https://github.com/samvera/hyrax/blob/master/app/models/admin_set.rb

      # Query AdminSet record by title
      # @input [String] - Title
      # :nocov:
      def self.find(id)
        ::AdminSet.find(id)
      end
      # :nocov:
    end
  end
end
