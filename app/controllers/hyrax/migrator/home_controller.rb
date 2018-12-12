# frozen_string_literal:true

require_dependency 'hyrax/migrator/application_controller'

module Hyrax
  module Migrator
    ##
    # Applications generic home controller
    class HomeController < ApplicationController
      def index; end
    end
  end
end
