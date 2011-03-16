# coding: utf-8

module PDF
  module Preflight
    module Receivers

      # For PDFX/1a, every page must have MediaBox, plus either ArtBox or
      # TrimBox
      #
      class PrintBoxes
        attr_reader :message

        def initialize
          @message = nil
        end

        def begin_page(hash = {})
          puts hash.inspect
          if hash[:MediaBox].nil?
            @message ||= "every page must have a MediaBox"
          elsif hash[:ArtBox].nil? && hash[:TrimBox].nil?
            @message ||= "every page must have either an ArtBox or a TrimBox"
          elsif hash[:ArtBox] && hash[:TrimBox]
            @message ||= "no page can have both ArtBox and TrimBox"
          end
        end
      end
    end
  end
end
