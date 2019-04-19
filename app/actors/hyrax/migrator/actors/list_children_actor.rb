# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Calls ListChildrenService to get children into work
  class ListChildrenActor < Hyrax::Migrator::Actors::AbstractActor
    HAS_CHILD = 'Children added.'
    NO_CHILD = 'No children to add.'

    aasm do
      state :list_children_initial, initial: true
      state :list_children_succeeded, :list_children_failed

      event :list_children_initial do
        transitions from:
                      %i[list_children_initial list_children_failed],
                    to: :list_children_initial
      end
      event :list_children_failed, after: :post_fail do
        transitions from: :list_children_initial,
                    to: :list_children_failed
      end
      event :list_children_succeeded, after: :post_success do
        transitions from: :list_children_initial,
                    to: :list_children_succeeded
      end
    end

    def create(work)
      super
      list_children_initial
      update_work(aasm.current_state)
      lcs = Hyrax::Migrator::Services::ListChildrenService.new(work, config)
      @children = lcs.list_children
      @children ? list_children_succeeded : list_children_failed
    rescue StandardError => e
      list_children_failed
      log("did not obtain children: #{e.message}")
    end

    private

    def post_success
      if @children.empty?
        message = NO_CHILD
      else
        @work.env[:work_members_attributes] = @children
        message = HAS_CHILD
      end
      succeeded(aasm.current_state, "Work #{@work.pid} #{message}", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed to acquire children.", Hyrax::Migrator::Work::FAIL)
    end
  end
end
