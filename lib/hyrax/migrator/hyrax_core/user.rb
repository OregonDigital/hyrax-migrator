# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    # Access the Hyrax actor stack for work persistence
    class User
      ## No coverage for Hyrax application integration to eliminate dependencies
      # :nocov:
      def self.find(email)
        ::User.where(email: email).first
      end
      # :nocov:
    end
  end
end
