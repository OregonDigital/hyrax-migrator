# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Retrieves content file checksums from manifest files in the bag
  class FileIdentityActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :file_identity_initial, initial: true
      state :file_identity_succeeded, :file_identity_failed

      event :file_identity_initial do
        transitions from: %i[file_identity_initial file_identity_failed],
                    to: :file_identity_initial
      end
      event :file_identity_failed, after: :post_fail do
        transitions from: :file_identity_initial,
                    to: :file_identity_failed
      end
      event :file_identity_succeeded, after: :post_success do
        transitions from: :file_identity_initial,
                    to: :file_identity_succeeded
      end
    end

    def create(work)
      super
      file_identity_initial
      update_work(aasm.current_state)
      @checksums = service.content_file_checksums
      @checksums ? file_identity_succeeded : file_identity_failed
    rescue StandardError => e
      file_identity_failed
      log("failed retrieving file checksums: #{e.message} : #{e.backtrace}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::LoadFileIdentityService.new(@work.working_directory)
    end
    #:nocov:

    def post_success
      @work.env[:files] = @checksums
      succeeded(aasm.current_state, "Work #{@work.pid} Successfully retrieved checksums data from bag manifest files.", Hyrax::Migrator::Work::SUCCESS)
    end

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} Unable to retrieve checksums data from bag manifest files.", Hyrax::Migrator::Work::FAIL)
    end
  end
end
