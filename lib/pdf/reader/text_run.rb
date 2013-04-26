# coding: utf-8

class PDF::Reader
  # A value object that represents one or more consecutive characters on a page.
  class TextRun
    include Comparable

    attr_reader :text, :glyphs

    alias :to_s :text

    def self.create_monospaced_run(x, y, font_size, text)
      curr_x = x
      glyphs = []
      text.each_char do |char|
        glyphs << GlyphPosition.new(curr_x, y, font_size, font_size, "courier", char)
        curr_x += font_size
      end
      PDF::Reader::TextRun.new(glyphs)
    end

    def initialize(glyphs)
      @glyphs = glyphs
      # TODO: double check that all glyphs have same font size, y, are in increasing x order?
      self.update_text
    end

    def update_text
      s = ""
      @glyphs.each do |glyph|
        s << glyph.glyph
      end
      @text = s
      # reset width
      @width = nil
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

    def width
      @width ||= @glyphs.last.endx - @glyphs.first.x
    end

    def x
      @x ||= @glyphs.first.x
    end

    def y
      @y ||= @glyphs.first.y
    end

    def font_size
      @font_size ||= @glyphs.first.font_size
    end

    def font_name
      @font_name ||= @glyphs.first.font_name
    end

    def endx
      @endx ||= x + width
    end

    def mean_character_width
      width / character_count
    end

    def mergable?(other)
      PDF::Reader::GlyphPosition.mergable?(@glyphs.last, other.glyphs.first)
    end

    def +(other)
      raise ArgumentError, "#{other} cannot be merged with this run" unless mergable?(other)

      TextRun.new(glyphs + other.glyphs)
    end

    def inspect
      "'#{text}' (#{@glyphs.length} glyphs) w:%.2f f:#{font_size} @{%.2f, %.2f}" % [width, x, y]
    end

    private

    def mergable_range
      @mergable_range ||= Range.new(endx - 3, endx + font_size)
    end

    def character_count
      # TODO: can we just use a count of the glyph array?
      if text.size == 1
        1.0
      elsif text.respond_to?(:bytesize)
        # M17N aware VM
        # so we can trust String#size to return a character count
        text.size.to_f
      else
        text.unpack("U*").size.to_f
      end
    end
  end
end
