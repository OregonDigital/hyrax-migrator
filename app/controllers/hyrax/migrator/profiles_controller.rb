require 'yaml'

module Hyrax::Migrator
  class ProfilesController < ApplicationController

    def show
      @work = Work.find_by(pid: params[:id])
      @profile = YAML.load_file(File.join(@work.working_directory, "data/#{params[:id]}_profile.yml"))
      render 'show'
    end
  end
end
