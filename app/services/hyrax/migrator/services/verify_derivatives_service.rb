# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to verify that derivatives for the content exist for the migrated asset
  class VerifyDerivativesService
    def initialize(asset_item, original_profile)
      @work = asset_item
      @original_profile = original_profile
    end

    # Given derivatives info from the original profile, verify that the derivatives
    # were successfully created after migrating the new asset
    def verify
      errors = []

      @work.file_sets.each do |file_set|
        result = verify_file_set(file_set)
        errors << result if result.present?
      end

      errors
    rescue StandardError => e
      puts e.message
    end

    # Return error (String) if found, otherwise return nil if no errors
    def verify_file_set(object)
      fsc = file_set.class

      case object.mime_type
      when *fsc.pdf_mime_types             then check_pdf_derivatives(object)
      when *fsc.office_document_mime_types then check_office_document_derivatives(object)
      when *fsc.audio_mime_types           then check_audio_derivatives(object)
      when *fsc.video_mime_types           then check_video_derivatives(object)
      when *fsc.image_mime_types           then check_image_derivatives(object)
      end
    end

    def all_derivative_paths(file_set)
      Hyrax::Migrator::HyraxCore::DerivativePath.new(file_set).all_paths
    end

    def check_pdf_derivatives(file_set)
      # check thumbnail exists?
      # check page count (it should match page count from OD1)
      #
      # TODO: return errors if any
    end

    def check_office_document_derivatives(file_set)
      # check thumbnail exists?
      # check extracted_text exists?
      # check page count (it should match page count from OD1)
      #
      # TODO: return errors if any
    end

    def check_audio_derivatives(file_set)
      # check thumbnail exists?
      # check mp3 exists?
      # check ogg exists?
      #
      # TODO: return errors if any
    end

    def check_video_derivatives(file_set)
      # check thumbnail exists?
      # check webm exists?
      # check mp4 exists?
      #
      # TODO: return errors if any
    end

    def check_image_derivatives(file_set)
      # check thumbnail (jpg) exists?
      # check zoomable (jp2) exists?
      #
      # TODO: return errors if any
    end

    ## Return derivatives info for the migrated asset (OD2)
    # @return hash (with derivatives info)
    def migrated_info
      original_info = @original_profile['derivatives_info']

      # TODO: return array of hashes (one for each file_set)
      # @work.file_sets.each do |file_set|
      #   {
      #     has_thumbnail: true,
      #
      #     # document
      #     has_content_ocr: true,
      #     page_count: 236,
      #
      #     # audio
      #     has_content_ogg: true,
      #     has_content_mp3: true,
      #
      #     # image
      #     has_medium_image: true,
      #     has_pyramidal_image: true,
      #
      #     # video
      #     has_content_mp4: true,
      #     has_content_jpg: true
      #   }
      # end
    end
  end
end
