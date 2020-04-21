# frozen_string_literal: true

require 'rdf'

module Hyrax::Migrator::Actors
  # calls RequiredFieldsService
  class RequiredFieldsActor < Hyrax::Migrator::Actors::AbstractActor
    include RDF

    aasm do
      state :required_fields_initial, initial: true
      state :required_fields_succeeded, :required_fields_failed

      event :required_fields_initial do
        transitions from:
                    %i[required_fields_initial required_fields_failed],
                    to: :required_fields_initial
      end
      event :required_fields_failed, after: :post_fail do
        transitions from: :required_fields_initial,
                    to: :required_fields_failed
      end
      event :required_fields_succeeded, after: :post_success do
        transitions from: :required_fields_initial,
                    to: :required_fields_succeeded
      end
    end

    def create(work)
      super
      required_fields_initial
      update_work(aasm.current_state)
      @required_fields = service.verify_fields
      @required_fields.empty? ? required_fields_succeeded : required_fields_failed
    rescue StandardError => e
      required_fields_failed
      log("failed required fields: #{e.message} : #{e.backtrace}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::RequiredFieldsService.new(work, config)
    end
    #:nocov:

    def post_success
      succeeded(aasm.current_state, "Work #{@work.pid} required fields checked.", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} required fields failed.", Hyrax::Migrator::Work::FAIL)
      @work.env[:errors] ||= []
      @work.env[:errors].concat @required_fields unless @required_fields.blank?
    end
  end
end
