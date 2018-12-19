# frozen_string_literal: true

require 'bagit'

module Hyrax
  module Migrator
    module Actors
      # Runs validation on the bag
      class BagValidatorActor < Hyrax::Migrator::Actors::AbstractActor
        include AASM
        include BagIt

        aasm do
          state :bag_validator_initial, initial: true
          state :bag_validator_succeeded, :bag_validator_failed

          event :bag_validator_initial do
            transitions from: %i[bag_validator_initial bag_validator_failed], to: :bag_validator_initial
          end
          event :bag_validator_failed do
            transitions from: :bag_validator_initial, to: :bag_validator_failed
          end
          event :bag_validator_succeeded, after: :post_success do
            transitions from: :bag_validator_initial, to: :bag_validator_succeeded
          end
        end

        def create(work)
          @work = work
          bag_validator_initial
          update_work(@work)
          bag = BagIt::Bag.new work.file_path
          bag.valid? ? bag_validator_succeeded : bag_validator_failed
          update_work(@work)
        rescue StandardError => e
          log("failed bag validation: #{e.message}")
        end

        private

        def post_success
          next_actor_for(@work)
        end

        def log(message)
          Rails.logger.warn "#{@work.pid} #{message}"
        end

        def update_work(work)
          work.aasm_state = aasm.current_state
          work.save
        end
      end
    end
  end
end
