# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Determine if children && children exist?
  class ChildrenAuditActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :children_audit_initial, initial: true
      state :children_audit_succeeded, :children_audit_failed

      event :children_audit_initial do
        transitions from: %i[children_audit_initial children_audit_failed],
                    to: :children_audit_initial
      end
      event :children_audit_failed, after: :post_fail do
        transitions from: :children_audit_initial,
                    to: :children_audit_failed
      end
      event :children_audit_succeeded, after: :post_success do
        transitions from: :children_audit_initial,
                    to: :children_audit_succeeded
      end
    end

    def create(work)
      super
      children_audit_initial
      update_work(aasm.current_state)
      process
    rescue StandardError => e
      children_audit_failed
      log("failed during children audit: #{e.message} : #{e.backtrace}")
    end

    private

    def process
      if @work.env[:children].blank?
        children_audit_succeeded
      else
        @result = service.audit
        @result == true ? children_audit_succeeded : children_audit_failed
      end
    end

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::ChildrenAuditService.new(@work, config)
    end
    #:nocov:

    def post_fail
      message = "#{@result} of #{@work.env[:children].size} children are persisted."
      failed(aasm.current_state, "Work #{@work.pid}: #{message}", Hyrax::Migrator::Work::FAIL)
    end

    def post_success
      succeeded(aasm.current_state, "Work #{@work.pid} children audit was successful.", Hyrax::Migrator::Work::SUCCESS)
    end
  end
end
