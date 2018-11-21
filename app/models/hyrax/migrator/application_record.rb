module Hyrax
  module Migrator
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
