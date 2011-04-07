# coding: utf-8

module Preflight
  module Rules

    # For each page MediaBox must be the biggest box, followed by the
    # BleedBox or ArtBox, followed by the TrimBox.
    #
    class BoxNesting
      attr_reader :messages

      def initialize
        @messages = []
        @page_num = 0
      end

      def begin_page(hash = {})
        @page_num += 1

        media  = hash[:MediaBox]
        bleed  = hash[:BleedBox]
        trim   = hash[:TrimBox]
        art    = hash[:ArtBox]

        if media && bleed && (bleed[2] > media[2] || bleed[3] > media[3])
          @messages << "BleedBox must be smaller than MediaBox (page #{@page_num})"
        elsif trim && bleed && (trim[2] > bleed[2] || trim[3] > bleed[3])
          @messages << "TrimBox must be smaller than BleedBox (page #{@page_num})"
        elsif art && bleed && (art[2] > bleed[2] || art[3] > bleed[3])
          @messages << "ArtBox must be smaller than BleedBox (page #{@page_num})"
        elsif trim && media && (trim[2] > media[2] || trim[3] > media[3])
          @messages << "TrimBox must be smaller than MediaBox (page #{@page_num})"
        elsif art && media && (art[2] > media[2] || art[3] > media[3])
          @messages << "ArtBox must be smaller than MediaBox (page #{@page_num})"
        end
      end
    end
  end
end
