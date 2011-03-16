# coding: utf-8

module PDF
  module Preflight
    module Receivers

      # For each page MediaBox must be the biggest box, followed by the 
      # BleedBox or ArtBox, followed by the TrimBox.
      #
      class BoxNesting
        attr_reader :message

        def initialize
          @message = nil
        end

        def begin_page(hash = {})
          media  = hash[:MediaBox]
          bleed  = hash[:BleedBox]
          trim   = hash[:TrimBox]
          art    = hash[:ArtBox]

          if media && bleed && (bleed[2] > media[2] || bleed[3] > media[3])
            @message ||= "BleedBox must be smaller than MediaBox"
          elsif trim && bleed && (trim[2] > bleed[2] || trim[3] > bleed[3])
            @message ||= "TrimBox must be smaller than BleedBox"
          elsif art && bleed && (art[2] > bleed[2] || art[3] > bleed[3])
            @message ||= "ArtBox must be smaller than BleedBox"
          elsif trim && media && (trim[2] > media[2] || trim[3] > media[3])
            @message ||= "TrimBox must be smaller than MediaBox"
          elsif art && media && (art[2] > media[2] || art[3] > media[3])
            @message ||= "ArtBox must be smaller than MediaBox"
          end
        end
      end
    end
  end
end
