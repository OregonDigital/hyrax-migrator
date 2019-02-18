# frozen_string_literal: true

module Hyrax::Migrator
  # A work represents the bag
  class Work < ApplicationRecord
    include Hyrax::Migrator::HasWorkingDirectory

    SUCCESS = 'success'
    FAIL = 'fail'

    serialize :env, Hash

    ##
    # Defaults to file_path if the module providing this method
    # has been intentionally removed.
    def working_directory
      if defined?(super)
        super
      else
        # :nocov: No good way to test this since it depends on super
        self[:file_path]
        # :nocov:
      end
    end

    ##
    # Defaults to noop if the module providing this method
    # has been intentially removed.
    def remove_temp_directory
      if defined?(super)
        super
      else
        # :nocov: No good way to test this since it depends on super
        true
        # :nocov:
      end
    end
  end
end
