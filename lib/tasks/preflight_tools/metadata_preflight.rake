# frozen_string_literal:true

# Requires a work dir with copies of crosswalk, crosswalk_overrides, and required_fields yml files
# Also a list of pids in the work_dir, one pid per line
# Will write a report of any errors found to the work dir
# To use: rake preflight_tools:metadata_preflight work_dir=/data1/batch/some_dir pidlist=list.txt
# If verbose=true then the attributes will be displayed

namespace :preflight_tools do
  desc 'for migration preflight check of metadata'
  task metadata_preflight: :environment do
    require 'hyrax/migrator/crosswalk_metadata_preflight'
    require 'hyrax/migrator/required_fields'
    init
    pids.each do |pid|
      begin
        @errors << "Working on #{pid}..."
        reset_crosswalk(pid)
        crosswalk_result = @crosswalk_service.crosswalk
        reset_required(crosswalk_result)
        required_result = @required_service.verify_fields
        concat_errors(crosswalk_result[:errors], required_result)
        verbose_display(pid, crosswalk_result.except(:errors)) if ENV.include? 'verbose'
      rescue StandardError => e
        @errors << "Could not check #{pid}, error message: #{e.message}"
        next
      end
    end
    write_errors
    @report.close
  end
end

def pids
  pids = []
  File.readlines(File.join(@work_dir, ENV['pidlist'])).each do |line|
    pids << line.strip
  end
  pids
end

def init
  @work_dir = ENV['work_dir']
  datetime_today = Time.zone.now.strftime('%Y%m%d%H%M%S') # "20171021125903"
  @report = File.open(File.join(@work_dir, "report_#{datetime_today}.txt"), 'w')
  @crosswalk_service = Hyrax::Migrator::CrosswalkMetadataPreflight.new(crosswalk_file, crosswalk_overrides_file)
  @required_service = Hyrax::Migrator::RequiredFields.new(required_fields_file)
  @errors = []
end

def concat_errors(crosswalk_result_errors, required_result)
  @errors.concat crosswalk_result_errors unless crosswalk_result_errors.blank?
  @errors.concat required_result unless required_result.blank?
end

def reset_crosswalk(pid)
  @crosswalk_service.graph = create_graph(GenericAsset.find(pid))
  @crosswalk_service.errors = []
  @crosswalk_service.result = {}
end

def reset_required(attributes)
  @required_service.attributes = attributes
end

def crosswalk_overrides_file
  File.join(@work_dir, 'crosswalk_overrides.yml')
end

def crosswalk_file
  File.join(@work_dir, 'crosswalk.yml')
end

def required_fields_file
  File.join(@work_dir, 'required_fields.yml')
end

def create_graph(item)
  item.datastreams['descMetadata'].graph
end

def verbose_display(pid, attributes)
  puts "Attributes for #{pid}..."
  attributes.each do |attr|
    puts attr.to_s
  end
end

def write_errors
  @errors.each do |e|
    @report.puts e
  end
end
