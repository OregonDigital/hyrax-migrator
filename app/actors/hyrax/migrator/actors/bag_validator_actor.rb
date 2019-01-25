# frozen_string_literal: true

require 'bagit'

module Hyrax::Migrator::Actors
  # Runs validation on the bag
  class BagValidatorActor < Hyrax::Migrator::Actors::AbstractActor
    include BagIt

    aasm do
      state :bag_validator_initial, initial: true
      state :bag_validator_succeeded, :bag_validator_failed

      event :bag_validator_initial do
        transitions from: %i[bag_validator_initial bag_validator_failed],
                    to: :bag_validator_initial
      end
      event :bag_validator_failed, after: :post_fail do
        transitions from: :bag_validator_initial,
                    to: :bag_validator_failed
      end
      event :bag_validator_succeeded, after: :post_success do
        transitions from: :bag_validator_initial,
                    to: :bag_validator_succeeded
      end
    end

    def create(work)
      super
      bag_validator_initial
      update_work
      bag = BagIt::Bag.new @work.file_path
      bag.valid? ? bag_validator_succeeded : bag_validator_failed
    rescue StandardError => e
      log("failed bag validation: #{e.message}")
    end

    private

    def post_success
      update_work
      call_next_actor
    end

    def post_fail
      update_work
    end

    def update_work
      @work.aasm_state = aasm.current_state
      @work.save
    end
  end
end
