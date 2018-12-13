module Hyrax::Migrator
  class Work < ApplicationRecord
    serialize :env, Hash
  end
end
