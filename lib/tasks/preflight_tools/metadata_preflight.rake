# frozen_string_literal:true

# Requires a work dir with copies of crosswalk and overrides yml files
# Also a list of pids in the work_dir, one pid per line
# Will write a report of any errors found to the work dir
# To use: rake preflight_tools:metadata_preflight workdir=/data1/batch/some_dir pidlist=list.txt
# If verbose=true then the attributes will be displayed

namespace :preflight_tools do
  desc 'for migration preflight check of metadata'
  task metadata_preflight: :environment do
    require 'hyrax/migrator/crosswalk_metadata_preflight'
    init
    pids.each do |pid|
      @errors << "Working on #{pid}..."
      @service.graph = create_graph(GenericAsset.find(pid))
      @service.errors = []
      @service.result = {}
      @result = @service.crosswalk
      @errors.concat @result[:errors]
      verbose_display(pid, @result.except(:errors)) if ENV.include? 'verbose'
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
  @service = Hyrax::Migrator::CrosswalkMetadataPreflight.new(crosswalk_file, crosswalk_overrides_file)
  @errors = []
end

def crosswalk_overrides_file
  File.join(@work_dir, 'crosswalk_overrides.yml')
end

def crosswalk_file
  File.join(@work_dir, 'crosswalk.yml')
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
