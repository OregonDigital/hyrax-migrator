# frozen_string_literal: true

module Hyrax
  module Migrator
    ##
    # Base application ActiveRecord class
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
