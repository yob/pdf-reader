# coding: utf-8

require 'afm'
require 'pdf/reader/synchronized_cache'

module AFM
  # this is a monkey patch for the AFM gem. hopefully my patch will be accepted
  # upstream and I can drop this
  class Font
    def metrics_for_name(name)
      @char_metrics[name.to_s]
    end
  end
end

class PDF::Reader
  module WidthCalculator

    # Type1 fonts can be one of 14 "built in" standard fonts. In these cases,
    # the reader is expected to have it's own copy of the font metrics.
    # see Section 9.6.2.2, PDF 32000-1:2008, pp 256
    class BuiltIn

      def initialize(font)
        @font = font
        @@all_metrics ||= PDF::Reader::SynchronizedCache.new

        metrics_path = File.join(File.dirname(__FILE__), "..","afm","#{font.basefont}.afm")

        if File.file?(metrics_path)
          @metrics = @@all_metrics[metrics_path] ||= AFM::Font.new(metrics_path)
        else
          raise ArgumentError, "No built-in metrics for #{font.basefont}"
        end
      end

      def glyph_width(code_point)
        return 0 if code_point.nil? || code_point < 0

        m = @metrics.metrics_for(code_point)
        if m.nil?
          name = @font.encoding.int_to_name(code_point)
          m = @metrics.metrics_for_name(name)
        end

        if m
          m[:wx]
        elsif @font.widths[code_point - 1]
          @font.widths[code_point - 1]
        else
          raise ArgumentError, "Unknown glyph width for #{codepoint}"
        end
      end

    end
  end
end
