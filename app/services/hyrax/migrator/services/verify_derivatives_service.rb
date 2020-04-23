# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to verify that derivatives for the content exist for the migrated asset
  class VerifyDerivativesService
    def initialize(asset_item, original_profile)
      @work = asset_item
      @original_profile = original_profile
      @verification_errors = []
    end

    # Given derivatives info from the original profile, verify that the derivatives
    # were successfully created after migrating the new asset
    def verify
      @work.file_sets.each do |file_set|
        verify_file_set(file_set)
      end

      @verification_errors
    rescue StandardError => e
      puts e.message
    end

    # Return error list Array
    def verify_file_set(object)
      fsc = object.class

      case object.mime_type
      when *fsc.pdf_mime_types             then check_pdf_derivatives(object)
      when *fsc.office_document_mime_types then check_office_document_derivatives(object)
      when *fsc.audio_mime_types           then check_audio_derivatives(object)
      when *fsc.video_mime_types           then check_video_derivatives(object)
      when *fsc.image_mime_types           then check_image_derivatives(object)
      end
    end

    def check_pdf_derivatives(file_set)
      check_thumbnail(file_set)
      check_page_count(file_set)
    end

    def check_office_document_derivatives(file_set)
      check_thumbnail(file_set)
      check_extracted_content(file_set)
      check_page_count(file_set)
    end

    def check_audio_derivatives(file_set)
      check_thumbnail(file_set)
      check_file_type(file_set, 'mp3')
      check_file_type(file_set, 'ogg')
    end

    def check_video_derivatives(file_set)
      check_thumbnail(file_set)
      check_file_type(file_set, 'webm')
      check_file_type(file_set, 'mp4')
    end

    def check_image_derivatives(file_set)
      check_thumbnail(file_set)
      check_file_type(file_set, 'jp2')
    end

    def all_derivatives(file_set)
      Hyrax::Migrator::HyraxCore::DerivativePath.new(file_set).all_paths.map { |f| File.basename(f) }
    end

    def check_thumbnail(file_set)
      has_thumbnail = info_for_migrated(file_set)[:has_thumbnail]
      @verification_errors << "Missing thumbnail in #{item.id}, file_set #{file_set.id}." unless has_thumbnail == true
    end

    def check_page_count(file_set)
      original_count = @original_profile['derivatives_info']['page_count']
      new_count = info_for_migrated(file_set)[:page_count]
      @verification_errors << "Page count does not match for work #{item.id}, file_set #{file_set.id}: original count #{original_count}, new count: #{new_count}" unless original_count == new_count
    end

    def check_extracted_content(file_set)
      @verification_errors << "Missing extracted text for work #{item.id}, file_set #{file_set.id}." unless info_for_migrated(file_set)[:has_extracted_text]
    end

    def check_file_type(file_set, extension)
      @verification_errors << "Missing #{extension} derivative for work #{item.id}, file_set #{file_set.id}." unless derivatives_for_reference(file_set, extension).present?
    end

    def derivatives_for_reference(file_set, extension)
      all_derivatives(file_set).select { |b| File.extname(b) == ".#{extension}" }
    end

    ## Return derivatives info for the migrated asset (OD2)
    # @return hash (with derivatives info)
    def info_for_migrated_asset
      @work.file_sets.map do |f|
        info_for_migrated(f)
      end
    end

    def info_for_migrated(file_set)
      {
        file_set_id: file_set.id,
        has_thumbnail: all_derivatives(file_set).select { |b| b.match 'thumbnail' }.present?,
        has_extracted_text: file_set.extracted_text.present?,
        page_count: derivatives_for_reference(file_set, 'jp2').count,
        has_content_ogg: derivatives_for_reference(file_set, 'ogg').present?,
        has_content_mp3: derivatives_for_reference(file_set, 'mp3').present?,
        has_zoomable_image: derivatives_for_reference(file_set, 'jp2').present?,
        has_content_mp4: derivatives_for_reference(file_set, 'mp4').present?,
        has_content_jpg: derivatives_for_reference(file_set, 'jpg').present?
      }
    end
  end
end
