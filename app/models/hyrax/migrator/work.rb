# frozen_string_literal: true

require 'bagit'

module Hyrax::Migrator
  # A work represents the bag
  class Work < ApplicationRecord
    include BagIt

    serialize :env, Hash

    def bag
      @bag ||= BagIt::Bag.new(file_path)
    end
  end
end
