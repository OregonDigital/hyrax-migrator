# frozen_string_literal: true

module Hyrax
  module Migrator
    ##
    # Base application ActionController class
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
    end
  end
end
