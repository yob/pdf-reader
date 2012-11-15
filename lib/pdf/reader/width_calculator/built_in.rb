# coding: utf-8

class PDF::Reader
  module WidthCalculator

    # Type1 fonts can be one of 14 "built in" standard fonts. In these cases,
    # the reader is expected to have it's own copy of the font metrics.
    # see Section 9.6.2.2, PDF 32000-1:2008, pp 256
    class BuiltIn

      def initialize(font)
        @font = font
      end

      def glyph_width(code_point)
        return 0 if code_point.nil? || code_point < 0

        if @font.basefont == :Helvetica
          return PDF::Reader::AFM::Helvetica[code_point]
        else
          # TODO the other 13 built in fonts
          return 500
        end
      end
    end
  end
end
