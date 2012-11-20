# coding: utf-8

require 'afm'

class PDF::Reader
  module WidthCalculator

    # Type1 fonts can be one of 14 "built in" standard fonts. In these cases,
    # the reader is expected to have it's own copy of the font metrics.
    # see Section 9.6.2.2, PDF 32000-1:2008, pp 256
    class BuiltIn

      BUILT_INS = [ :Courier, :Helvetica, :"Times-Roman", :"Symbol", :"ZapfDingbats",
                      :"Courier-Bold", :"Courier-Oblique", :"Courier-BoldOblique",
                      :"Times-Bold", "Times-Italic", :"Times-BoldItalic",
                      :"Helvetica-Bold", :"Helvetica-Oblique", :"Helvetica-BoldOblique" ]

      def initialize(font)
        @font = font
        @metrics_path = File.join(File.dirname(__FILE__), "..","afm","#{font.basefont}.afm")

        if File.file?(@metrics_path)
          @metrics = AFM::Font.new(@metrics_path)
        else
          raise ArgumentError, "No built-in metrics for #{font.basefont}"
        end
      end

      def glyph_width(code_point)
        return 0 if code_point.nil? || code_point < 0

        m = @metrics.metrics_for(code_point)
        m[:wx]
      end

    end
  end
end
