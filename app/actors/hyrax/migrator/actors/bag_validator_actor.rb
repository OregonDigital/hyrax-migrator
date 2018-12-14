module Hyrax
  module Migrator
    module Actors
      # Runs validation on the bag
      class BagValidatorActor < Hyrax::Migrator::Actors::AbstractActor
        include AASM
        include BagIt

        aasm do
          state :bag_validator_initial, initial: true
          state :bag_validator_succeeded
          event :succeeded, after: :post_success do
            transitions from: :bag_validator_initial, to: :bag_validator_succeeded
          end
        end

        def create(work)
          @work = work
          update_work(@work)
          bag = BagIt::Bag.new work.file_path
          if bag.valid?
            update_work(@work)
          else
            log("failed bag validation")
          end
        rescue StandardError => e
          log("failed bag validation: #{e.message}")
        end

        private

        def post_success
          next_actor.create(@work)
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
