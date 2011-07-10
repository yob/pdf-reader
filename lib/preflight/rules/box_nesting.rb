# coding: utf-8

module Preflight
  module Rules

    # For each page MediaBox must be the biggest box, followed by the
    # BleedBox or ArtBox, followed by the TrimBox.
    #
    class BoxNesting

      def check_page(page)
        media  = page.page_object[:MediaBox]
        bleed  = page.page_object[:BleedBox]
        trim   = page.page_object[:TrimBox]
        art    = page.page_object[:ArtBox]

        if media && bleed && (bleed[2] > media[2] || bleed[3] > media[3])
          ["BleedBox must be smaller than MediaBox (page #{page.number})"]
        elsif trim && bleed && (trim[2] > bleed[2] || trim[3] > bleed[3])
          ["TrimBox must be smaller than BleedBox (page #{page.number})"]
        elsif art && bleed && (art[2] > bleed[2] || art[3] > bleed[3])
          ["ArtBox must be smaller than BleedBox (page #{page.number})"]
        elsif trim && media && (trim[2] > media[2] || trim[3] > media[3])
          ["TrimBox must be smaller than MediaBox (page #{page.number})"]
        elsif art && media && (art[2] > media[2] || art[3] > media[3])
          ["ArtBox must be smaller than MediaBox (page #{page.number})"]
        else
          []
        end
      end
    end
  end
end
