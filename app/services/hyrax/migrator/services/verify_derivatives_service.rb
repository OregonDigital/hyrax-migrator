# frozen_string_literal:true

require 'yaml'

module Hyrax::Migrator::Services
  ##
  # A service to verify that derivatives for the content exist for the migrated asset
  class VerifyDerivativesService
    def initialize(migrator_work, original_profile)
      @work = migrator_work
      @original_profile = original_profile
    end

    # Given derivatives info from the original profile, verify that the derivatives
    # were successfully created after migrating the new asset
    def verify
      #
      # Verification options/psedocode
      #
      # Example:
      # pid = 'fx71bn65n'
      #
      # OD1:
      #
      # asset = GenericAsset.find("oregondigital:#{pid}")
      # asset.datastreams.to_a.map { |d| d.second }.select { |d| d.controlGroup == "E" }.map { |d| d.dsid }
      # => ["thumbnail", "content_ocr", "page-2", "page-3", ...]
      #
      # OD2:
      # w = ActiveFedora::Base.find("fx71bn65n")
      # fsd = OregonDigital::FileSetDerivativesService.new(w.file_sets.first)
      # fsd.sorted_derivative_urls('thumbnail')
      # => ["file:///data/tmp/shared/derivatives/td/96/k2/48/x-thumbnail.jpeg"]
      #
      # option (1)
      #
      # for each derivative filename in sorted_derivatives_url do
      #   case mime_type
      #     when pdf_mime_types             then check_pdf_derivatives(filename)
      #     when office_document_mime_types then check_office_document_derivatives(filename)
      #     when audio_mime_types           then check_audio_derivatives(filename)
      #     when video_mime_types           then check_video_derivatives(filename)
      #     when image_mime_types           then check_image_derivatives(filename)
      #   end
      # end
      #
      # option (2)
      #
      # find CreateDerivativesJobs and filter by pid/arguments, then query
      # sidekiq to find out if they are succcessful.
      #
      #
    end

    # def check_pdf_derivatives(filename)
    #
    #   check thumbnail exists?
    #
    #   check page count (it should match page count from OD1)
    #     page_count = OregonDigital::Derivatives::Image::Utils.page_count(filename)
    #
    #   return true
    # end
    #
    #
    # def check_office_document_derivatives(filename)
    #
    #   check thumbnail exists?
    #   check extracted_text exists?
    #
    #   check page count (it should match page count from OD1)
    #     page_count = OregonDigital::Derivatives::Image::Utils.page_count(filename)
    #
    #   return true
    # end
    #
    # def check_audio_derivatives(filename)
    #
    #   check thumbnail exists?
    #   check mp3 exists?
    #   check ogg exists?
    #
    #   return true
    # end
    #
    # def check_video_derivatives(filename)
    #
    #   check thumbnail exists?
    #   check webm exists?
    #   check mp4 exists?
    #
    #   return true
    # end
    #
    # def check_image_derivatives(filename)
    #
    #   check thumbnail (jpg) exists?
    #   check zoomable (jp2) exists?
    #
    #   return true
    # end
    #
    ## Return derivatives info for the migrated asset (OD2)
    # def migrated_info
    #   return [
    #     {
    #       label: :thumbnail,
    #       format: 'jpg',
    #       type: 'pdf'
    #     }
    #   ]
    # end
  end
end
