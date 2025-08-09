# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader
  module WidthCalculator
    # Type0 (or Composite) fonts are a "root font" that rely on a "descendant font"
    # to do the heavy lifting. The "descendant font" is a CID-Keyed font.
    # see Section 9.7.1, PDF 32000-1:2008, pp 267
    # so if we are calculating a Type0 font width, we just pass off to
    # the descendant font
    class TypeZero

      #: (PDF::Reader::Font) -> void
      def initialize(font)
        @font = font
      end

      #: (Integer?) -> Numeric
      def glyph_width(code_point)
        return 0 if code_point.nil? || code_point < 0

        if descendant_font = @font.descendantfonts.first
          descendant_font.glyph_width(code_point).to_f
        else
          0
        end
      end
    end
  end
end
