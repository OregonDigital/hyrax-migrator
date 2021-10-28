# frozen_string_literal: true

require 'yaml'

module Hyrax::Migrator
  # Display exported/migrated profiles for inspection
  class ProfilesController < ApplicationController
    def show
      @work = Work.find_by(pid: params[:id])
      @profile = YAML.load_file(File.join(@work.working_directory, "data/#{params[:id]}_profile.yml"))
      @hyrax_work = Hyrax::Migrator::HyraxCore::Asset.find(params[:id])
      @fields = fields
      @colls = colls
      render 'show'
    end

    def extract(val)
      str = val.respond_to?(:rdf_subject) ? val.rdf_subject.to_s : val
      str
    end

    def fields
      fields = {}
      @hyrax_work.as_json.each do |field, val|
        next if val.blank?

        fields[field] = val.respond_to?(:to_a) ? field_array(val) : extract(val)
      end
      fields
    end

    def field_array(val)
      arr = []
      val.each do |v|
        arr << extract(v)
      end
      arr
    end

    def colls
      colls = []
      @hyrax_work.member_of_collections.each do |coll|
        colls << coll.id
      end
      colls
    end
  end
end
