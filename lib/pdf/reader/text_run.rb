# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader
  # A value object that represents one or more consecutive characters on a page.
  class TextRun
    include Comparable

    #: PDF::Reader::Point
    attr_reader :origin

    #: Numeric
    attr_reader :width

    #: Numeric
    attr_reader :font_size

    #: String
    attr_reader :text

    alias :to_s :text

    #: (Numeric, Numeric, Numeric, Numeric, String) -> void
    def initialize(x, y, width, font_size, text)
      @origin = PDF::Reader::Point.new(x, y) #: PDF::Reader::Point
      @width = width
      @font_size = font_size
      @text = text
      @endx = nil #: Numeric | nil
      @endy = nil #: Numeric | nil
      @mergable_range = nil #: Range[Numeric] | nil
    end

    # Allows collections of TextRun objects to be sorted. They will be sorted
    # in order of their position on a cartesian plain - Top Left to Bottom Right
    #: (PDF::Reader::Point) -> Numeric
    def <=>(other)
      if x == other.x && y == other.y
        0
      elsif y < other.y
        1
      elsif y > other.y
        -1
      elsif x < other.x
        -1
      elsif x > other.x
        1
      else
        0 # Unreachable?
      end
    end

    #: () -> Numeric
    def x
      @origin.x
    end

    #: () -> Numeric
    def y
      @origin.y
    end

    #: () -> Numeric
    def endx
      @endx ||= @origin.x + width
    end

    #: () -> Numeric
    def endy
      @endy ||= @origin.y + font_size
    end

    #: () -> Numeric
    def mean_character_width
      @width / character_count
    end

    #: (PDF::Reader::TextRun) -> bool
    def mergable?(other)
      y.to_i == other.y.to_i && font_size == other.font_size && mergable_range.include?(other.x)
    end

    #: (PDF::Reader::TextRun) -> PDF::Reader::TextRun
    def +(other)
      raise ArgumentError, "#{other} cannot be merged with this run" unless mergable?(other)

      if (other.x - endx) <( font_size * 0.2)
        TextRun.new(x, y, other.endx - x, font_size, text + other.text)
      else
        TextRun.new(x, y, other.endx - x, font_size, "#{text} #{other.text}")
      end
    end

    #: () -> String
    def inspect
      "#{text} w:#{width} f:#{font_size} @#{x},#{y}"
    end

    #: (PDF::Reader::TextRun) -> bool
    def intersect?(other_run)
      x <= other_run.endx && endx >= other_run.x &&
        endy >= other_run.y && y <= other_run.endy
    end

    # return what percentage of this text run is overlapped by another run
    #: (PDF::Reader::TextRun) -> Numeric
    def intersection_area_percent(other_run)
      return 0 unless intersect?(other_run)

      dx = [endx, other_run.endx].min - [x, other_run.x].max
      dy = [endy, other_run.endy].min - [y, other_run.y].max
      intersection_area = dx*dy

      intersection_area.to_f / area
    end

    private

    #: () -> Numeric
    def area
      (endx - x) * (endy - y)
    end

    #: () -> Range[Numeric]
    def mergable_range
      @mergable_range ||= Range.new(endx - 3, endx + font_size)
    end

    # Assume string encoding is marked correctly and we can trust String#size to return a
    # character count
    #: () -> Float
    def character_count
      @text.size.to_f
    end
  end
end
