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
      end

      def self.rule_type
        :receiver
      end

      def begin_page(hash = {})
        media  = hash[:MediaBox]
        bleed  = hash[:BleedBox]
        trim   = hash[:TrimBox]
        art    = hash[:ArtBox]

        if media && bleed && (bleed[2] > media[2] || bleed[3] > media[3])
          @messages << "BleedBox must be smaller than MediaBox"
        elsif trim && bleed && (trim[2] > bleed[2] || trim[3] > bleed[3])
          @messages << "TrimBox must be smaller than BleedBox"
        elsif art && bleed && (art[2] > bleed[2] || art[3] > bleed[3])
          @messages << "ArtBox must be smaller than BleedBox"
        elsif trim && media && (trim[2] > media[2] || trim[3] > media[3])
          @messages << "TrimBox must be smaller than MediaBox"
        elsif art && media && (art[2] > media[2] || art[3] > media[3])
          @messages << "ArtBox must be smaller than MediaBox"
        end
      end
    end
  end
end
