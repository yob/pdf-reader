# coding: utf-8

class PDF::Reader
  # A value object that represents one or more consecutive characters on a page.
  class TextRun
    include Comparable

    MERGE_LIMIT = 12

    attr_reader :x, :y, :width, :text

    alias :to_s :text

    def initialize(x, y, width, text)
      @x = x
      @y = y
      @width = width
      @text = text
    end

    # Allows collections of TextRun objects to be sorted. They will be sorted
    # in order of their position on a cartesian plain - Top Left to Bottom Right
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
      end
    end

    def endx
      @endx ||= x + width
    end

    def mergable?(other)
      y.to_i == other.y.to_i && mergable_range.include?(other.x)
    end

    def +(other)
      raise ArgumentError, "#{other} cannot be merged with this run" unless mergable?(other)

      TextRun.new(x, y, other.endx - x, text + other.text)
    end

    def inspect
      "#{text} w:#{width} @#{x},#{y}"
    end

    private

    def mergable_range
      @mergable_range ||= Range.new(endx - 3, endx + MERGE_LIMIT)
    end
  end
end
