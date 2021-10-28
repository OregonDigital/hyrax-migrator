# frozen_string_literal: true

require 'yaml'

module Hyrax::Migrator
  # Provide access to inspect profiles by batch
  class BatchesController < ApplicationController
    def show
      @pids = pids
      render 'show'
    end

    def pids
      locations = Hyrax::Migrator::Services::BagFileLocationService.new([params[:id]], Hyrax::Migrator.config)
      locations.bags_to_ingest[params[:id]].map { |path| File.basename(path, File.extname(path)) }
    end
  end
end
