# coding: utf-8

class PDF::Reader
  class TextRun < Struct.new(:x, :y, :width, :text)
    include Comparable

    MERGE_LIMIT = 12

    alias :to_s :text

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
      x + width
    end

    def mergable?(other)
      y.to_i == other.y.to_i && Range.new(endx - 3, endx + MERGE_LIMIT).include?(other.x)
    end

    def mergable_by_pos?(otherx, othery)
      y.to_i == othery.to_i && Range.new(endx - 3, endx + MERGE_LIMIT).include?(otherx)
    end

    def +(other)
      raise ArgumentError, "#{other} cannot be merged with this run" unless mergable?(other)

      TextRun.new(x, y, other.endx - x, text + other.text)
    end

    def inspect
      "#{text} w:#{width} @#{x},#{y}"
    end
  end
end
