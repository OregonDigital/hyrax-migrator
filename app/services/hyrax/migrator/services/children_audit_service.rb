# frozen_string_literal:true

module Hyrax::Migrator::Services
  ##
  # A service to determine if all children are persisted
  class ChildrenAuditService
    def initialize(work, migrator_config)
      @work = work
      @config = migrator_config
    end

    def audit
      total_exists = 0
      @work.env[:work_members_attributes].each do |_k, val|
        child = Hyrax::Migrator::Work.find_by(pid: val['id'])
        total_exists += 1 unless child.blank? || child.status != Hyrax::Migrator::Work::SUCCESS
      end
      total_exists < @work.env[:work_members_attributes].size ? total_exists : true
    end
  end
end
