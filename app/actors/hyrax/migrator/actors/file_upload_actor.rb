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
      update_work(aasm.current_state)
      @uploaded_file = service.upload_file_content
      @handled_uploaded_files = handle_uploaded_file(@uploaded_file)
      @handled_uploaded_files ? file_upload_succeeded : file_upload_failed
    rescue StandardError => e
      file_upload_failed
      log("failed during file upload: #{e.message} : #{e.backtrace}")
    end

    private

    #:nocov:
    def service
      @service ||= Hyrax::Migrator::Services::FileUploadService.new(@work.working_directory, config)
    end
    #:nocov:

    def post_fail
      failed(aasm.current_state, "Work #{@work.pid} failed to upload original files.", Hyrax::Migrator::Work::FAIL)
    end

    def handle_uploaded_file(uploaded_file)
      return [uploaded_file] if uploaded_file['url'].present?

      return handle_no_content_found(uploaded_file) if uploaded_file['local_filename'].blank?

      local_file_uploaded = hyrax_file_uploaded.create
      [local_file_uploaded.id] if local_file_uploaded
    end

    def handle_no_content_found(file_hash)
      if config.content_file_can_be_nil.to_s == 'true'
        Rails.logger.warn "Skipping file upload for #{@work.pid}. No content found."
        return file_hash
      end

      raise StandardError, "could not find a content file for pid #{@work.pid}"
    end

    def post_success
      if @uploaded_file['url'].present?
        @work.env[:attributes][:remote_files] = @handled_uploaded_files
      elsif @uploaded_file['local_filename'].present?
        @work.env[:attributes][:uploaded_files] = @handled_uploaded_files
      end

      succeeded(aasm.current_state, "Work #{@work.pid} uploaded #{@handled_uploaded_files}.", Hyrax::Migrator::Work::SUCCESS)
    end

    def hyrax_file_uploaded
      @hyrax_file_uploaded ||= Hyrax::Migrator::HyraxCore::UploadedFile.new(
        user: user,
        uploaded_filename: @uploaded_file['local_filename']
      )
    end
  end
end
