# coding: utf-8

module Preflight
  module Rules

    # For PDFX/1a, every page must have MediaBox, plus either ArtBox or
    # TrimBox
    #
    class PrintBoxes

      def check_page(page)
        dict = page.attributes

        if dict[:MediaBox].nil?
          ["every page must have a MediaBox (page #{page.number})"]
        elsif dict[:ArtBox].nil? && dict[:TrimBox].nil?
          ["every page must have either an ArtBox or a TrimBox (page #{page.number})"]
        elsif dict[:ArtBox] && dict[:TrimBox]
          ["no page can have both ArtBox and TrimBox - TrimBox is preferred (page #{page.number})"]
        else
          []
        end
      end
    end
  end
end
