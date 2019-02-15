# frozen_string_literal: true

require 'zip'
require 'tmpdir'
require 'fileutils'

module Hyrax::Migrator
  # A work represents the bag
  class Work < ApplicationRecord
    include Hyrax::Migrator::HasWorkingDirectory

    SUCCESS = 'success'
    FAIL = 'fail'

    serialize :env, Hash
  end
end
