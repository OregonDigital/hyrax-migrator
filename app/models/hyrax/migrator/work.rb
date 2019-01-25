# frozen_string_literal: true

module Hyrax::Migrator
  # A work represents the bag
  class Work < ApplicationRecord
    serialize :env, Hash
  end
end
