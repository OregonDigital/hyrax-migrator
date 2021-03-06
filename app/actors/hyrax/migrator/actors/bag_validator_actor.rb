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
      update_work(aasm.current_state)
      bag = BagIt::Bag.new @work.working_directory
      bag.valid? ? bag_validator_succeeded : bag_validator_failed
    rescue StandardError => e
      log("failed bag validation: #{e.message} : #{e.backtrace}")
    end

    private

    def post_success
      succeeded(aasm.current_state, "Work #{@work.pid} Bag valid.", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} Bag invalid.", Hyrax::Migrator::Work::FAIL)
    end
  end
end
