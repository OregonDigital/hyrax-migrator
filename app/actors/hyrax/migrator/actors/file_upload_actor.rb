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
      # TODO: Refactor url parsing. I'm thinking the logic below would make more sense in the FileUploadService instead
      parsed_content_file = Addressable::URI.parse(@uploaded_file)
      if ["http", "https"].include?(parsed_content_file.schema)
        # TODO: set remote_files attribute
      else
        # set uploaded_files attribute
        local_file = File.open(@uploaded_file)
        local_file_uri = URI.join('file:///', @uploaded_file)
        uploaded = Hyrax::UploadedFile.create(user: config.migration_user, file_set_uri: local_file_uri, file: local_file)
        @work.env[:attributes].merge(uploaded_files: [uploaded.id])
        
        # NOTE: Example test for a local file for reference
        # f = File.open("/data/tmp/browse-everything/openaccessweekbanner-270.png")
        # u = ::User.where(email: "gregorio.luisramirez@oregonstate.edu").first
        # uploaded = Hyrax::UploadedFile.create(user: u, file_set_uri: "file:///data/tmp/browse-everything/openaccessweekbanner-270.png", file: f)
        # actor_env = Hyrax::Actors::Environment.new(Generic.find("hq37vn56b"), u.ability, {"uploaded_files"=>[uploaded.id]})
        # Hyrax::CurationConcern.actor.update(actor_env)
      end
      
      update_work
      call_next_actor
    end

    def update_work
      @work.aasm_state = aasm.current_state
      @work.save
    end

  end
end
