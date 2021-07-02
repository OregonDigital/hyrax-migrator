# frozen_string_literal:true

require 'bagit'
module Hyrax::Migrator::Services
  # requires a batch name, iterates through the batch and checks for changes for each work.
  # pass in custom actor stack able to handle required updates
  # eg: Hyrax::Migrator::Services::BatchUpdateService.new(batchname, { middleware_config: actors })
  # where actors = { actor_stack => ['Hyrax::Migrator::Actors::CrosswalkMetadataActor', 'Hyrax::Migrator::Actors::UpdateWorkActor', 'Hyrax::Migrator::Actors::TerminalActor'] }
  class BatchUpdateService < Hyrax::Migrator::Services::BagIngestService
    def initialize(input_batch_names, options)
      super
      raise StandardError, 'Middleware must be configured' if options[:middleware_config].nil?
    end

    def update
      location_service.bags_to_ingest.each do |_batch_name, bag_locations|
        bag_locations.each do |file_path|
          pid = parse_pid(file_path)
          work = Hyrax::Migrator::Work.find_by(pid: pid)
          next unless needs_update?(work)

          prepare(work) unless work.aasm_state.include? 'failed'
          Hyrax::Migrator::Jobs::MigrateWorkJob.perform_later(args(pid, file_path))
        end
      end
    end

    private

    def prepare(work)
      work.aasm_state = divine_state
      work.status = 'update'
      work.save
    end

    def divine_state
      actor = @options[:middleware_config][:actor_stack].first
      actor.split('::').last.gsub('Actor', 'Initial').underscore
    end

    def needs_update?(work)
      work.updated_at.to_date < export_date(work) || work.aasm_state == 'update_work_failed'
    end

    def export_date(work)
      Date.parse(BagIt::Bag.new(work.file_path).bag_info['Bagging-Date'])
    end

    def args(pid, file_path)
      args = { pid: pid, file_path: file_path, update: true }
      args.merge! @options
      args
    end
  end
end
