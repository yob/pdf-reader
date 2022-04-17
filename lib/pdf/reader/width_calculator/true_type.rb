# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader
  module WidthCalculator
    # Calculates the width of a glyph in a TrueType font
    class TrueType

      def initialize(font)
        @font = font

        if fd = @font.font_descriptor
          @missing_width = fd.missing_width
        else
          @missing_width = 0
        end
      end

      def glyph_width(code_point)
        return 0 if code_point.nil? || code_point < 0
        glyph_width_from_font(code_point) || glyph_width_from_descriptor(code_point) || 0
      end

      private

      #TODO convert Type3 units 1000 units => 1 text space unit
      def glyph_width_from_font(code_point)
        return if @font.widths.nil? || @font.widths.count == 0

        # in ruby a negative index is valid, and will go from the end of the array
        # which is undesireable in this case.
        first_char = @font.first_char
        if first_char && first_char <= code_point
          @font.widths.fetch(code_point - first_char, @missing_width.to_i).to_f
        else
          @missing_width.to_f
        end
      end

      def glyph_width_from_descriptor(code_point)
        # true type fonts will have most of their information contained
        # with-in a program inside the font descriptor, however the widths
        # may not be in standard PDF glyph widths (1000 units => 1 text space unit)
        # so this width will need to be scaled
        if fd = @font.font_descriptor
          if w = fd.glyph_width(code_point)
            w.to_f * fd.glyph_to_pdf_scale_factor.to_f
          end
        end
      end
    end
  end
end

