# frozen_string_literal:true

# Requires a work dir with copies of crosswalk and overrides yml files
# Also a list of pids in the work_dir, one pid per line
# Will write a report of any errors found to the work dir
# To use: rake preflight_tools:metadata_preflight workdir=/data1/batch/some_dir pidlist=list.txt
# If verbose=true then the attributes will be displayed

namespace :preflight_tools do
  desc 'for migration preflight check of metadata'
  task metadata_preflight: :environment do
    require 'hyrax/migrator/crosswalk_metadata'
    init
    pids.each do |pid|
      @errors << "Working on #{pid}..."
      attributes = crosswalk(GenericAsset.find(pid))
      verbose_display(pid, attributes) if ENV.include? 'verbose'
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
  datetime_today = Time.now.strftime('%Y%m%d%H%M%S') # "20171021125903"
  @report = File.open(File.join(@work_dir, "report_#{datetime_today}.txt"), 'w')
  @service = Hyrax::Migrator::CrosswalkMetadata.new(crosswalk_file, crosswalk_overrides_file)
  @errors = []
end

def crosswalk_overrides_file
  File.join(@work_dir, 'crosswalk_overrides.yml')
end

def crosswalk_file
  File.join(@work_dir, 'crosswalk.yml')
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

# returns result hash
def crosswalk(item)
  graph = create_graph(item)
  graph.statements.each do |statement|
    data = lookup(statement.predicate.to_s)
    next if data.nil?

    processed_obj = @service.process(data, statement.object)
    next if processed_obj.nil?

    @service.assemble_hash(data, processed_obj)
  end
  @service.result
end

# Load the nt file and return graph
def create_graph(item)
  item.datastreams['descMetadata'].graph
end

# Given an OD2 predicate, returns associated property data or nil
def lookup(predicate)
  result = @service.lookup(predicate)
  return result unless result.nil?

  @errors << "Predicate not found: #{predicate} during crosswalk"
  nil
end

##
# Generate the data necessary for a Rails nested attribute
def attributes_data(object)
  result = @service.attributes_data(object)
  return result unless result.nil?

  @errors << "Invalid URI #{object} found in crosswalk of #{@work.pid}"
  nil
end
