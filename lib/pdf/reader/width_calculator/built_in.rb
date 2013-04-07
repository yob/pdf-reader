# coding: utf-8

require 'afm'
require 'pdf/reader/synchronized_cache'

# monkey patch the afm gem to give us access to the metrics by glyph code. I've
# got a pull request to upstream so hopefully this can be removed soon. See
# https://github.com/halfbyte/afm/pull/3
class AFM::Font
  attr_reader :char_metrics_by_code

  # Loading a Font Metrics file by absolute path (no automatic font path resolution)
  def initialize(filename)
    @metadata = {}
    @char_metrics = {}
    @char_metrics_by_code = {}
    @kern_pairs = []
    File.open(filename) do |file|
      mode = :meta
      file.each_line do |line|
        case(line)
        when /^StartFontMetrics/ ; mode = :meta
        when /^StartCharMetrics/ ; mode = :char_metrics
        when /^EndCharMetrics/ ; mode = :meta
        when /^StartKernData/ ; mode = :kern_data
        when /^StartKernPairs/ ; mode = :kern_pairs
        when /^EndKernPairs/ ; mode = :kern_data
        when /^EndKernData/ ; mode = :meta
        else
          case(mode)
          when :meta
            if match = line.match(/^([\w]+) (.*)$/)
              @metadata[match[1]] = match[2]
            end
          when :char_metrics
            metrics = {}
            metrics[:charcode] = match[1].to_i if match = line.match(/C (-?\d+) *?;/)
            metrics[:wx] = match[1].to_i if match = line.match(/WX (-?\d+) *?;/)
            metrics[:name] = match[1] if match = line.match(/N ([.\w]+) *?;/)
            if match = line.match(/B (-?\d+) (-?\d+) (-?\d+) (-?\d+) *?;/)
              metrics[:boundingbox] = [match[1].to_i, match[2].to_i, match[3].to_i, match[4].to_i]
            end
            @char_metrics[metrics[:name]] = metrics if metrics[:name]
            @char_metrics_by_code[metrics[:charcode]] = metrics if metrics[:charcode] && metrics[:charcode] > 0
          when :kern_pairs
            if match = line.match(/^KPX ([.\w]+) ([.\w]+) (-?\d+)$/)
              @kern_pairs << [match[1], match[2], match[3].to_i]
            end
          end
        end
      end
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

        m = @metrics.char_metrics_by_code[code_point]
        if m.nil?
          names = @font.encoding.int_to_name(code_point)
          m = names.map { |name|
            @metrics.char_metrics[name.to_s]
          }.compact.first
        end

        if m
          m[:wx]
        elsif @font.widths[code_point - 1]
          @font.widths[code_point - 1]
        else
          raise ArgumentError, "Unknown glyph width for #{code_point} #{@font.basefont}"
        end
      end

    end
  end
end
