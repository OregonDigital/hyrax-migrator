# frozen_string_literal: true

module Hyrax::Migrator::Actors
  # Identifies the original files in the bag, uploads the content, and persists the paths in the works env
  class FileUploadActor < Hyrax::Migrator::Actors::AbstractActor
    aasm do
      state :file_upload_initial, initial: true
      state :file_upload_succeeded, :file_upload_failed

      event :file_upload_initial do
        transitions from: %i[file_upload_initial file_upload_failed],
                    to: :file_upload_initial
      end
      event :file_upload_failed, after: :post_fail do
        transitions from: :file_upload_initial,
                    to: :file_upload_failed
      end
      event :file_upload_succeeded, after: :post_success do
        transitions from: :file_upload_initial,
                    to: :file_upload_succeeded
      end
    end

    ##
    # Use the FileUploadService and configurations to upload the file from the bag and persis the new paths
    # in the works env
    def create(work)
      super
      file_upload_initial
      update_work
      @uploaded_file = service.upload_file_content
      @uploaded_file ? file_upload_succeeded : file_upload_failed
    rescue StandardError => e
      file_upload_failed
      log("failed during file upload: #{e.message}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::FileUploadService.new(@work.file_path, config)
    end
    #:nocov:

    def post_fail
      update_work
    end

    def post_success
      if @uploaded_file['url'].present?
        @work.env[:attributes].merge(remote_files: [@uploaded_file])
      else
        @work.env[:attributes].merge(uploaded_files: [hyrax_local_file_uploaded.id])
      end

      update_work
      call_next_actor
    end

    def hyrax_local_file_uploaded
      local_file = File.open(@uploaded_file['local_filename'])
      Hyrax::UploadedFile.create(user: current_user, file_set_uri: @uploaded_file['local_file_uri'], file: local_file)
    end

    def current_user
      @current_user = ::User.where(email: config.migration_user).first
    end

    def update_work
      @work.aasm_state = aasm.current_state
      @work.save
    end
  end
end
