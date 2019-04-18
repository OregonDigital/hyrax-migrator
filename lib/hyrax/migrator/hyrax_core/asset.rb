# frozen_string_literal:true

module Hyrax::Migrator
  module HyraxCore
    class Asset
      def self.find(id)
        ActiveFedora::Base.find(id)
      rescue
        nil
      end
    end
  end
end
