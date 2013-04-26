# coding: utf-8

class PDF::Reader

  # a value object that represents the location of a glyph on a page.
  class GlyphPosition
    attr_reader :x, :y, :width, :font_size, :glyph, :font_name

    alias :to_s :glyph

    def initialize(x, y, width, font_size, font_name, glyph)
      @x = x
      @y = y
      @width = width
      @font_size = font_size.floor
      @glyph = glyph
      @font_name = font_name
    end

    def endx
      @endx ||= x + width
    end

    def inspect
      "'#{glyph}' w:%.2f f:#{font_name}@#{font_size} @{%.2f, %.2f}" % [width, x, y]
    end

    def self.mergable?(a, b)
      result = a.y.to_i == b.y.to_i && a.font_size == b.font_size && a.font_name == b.font_name && (b.x - a.endx).abs < a.font_size

      # puts "Checking #{a.inspect} mergable with #{b.inspect} // #{(b.x - a.endx)}" # unless result
      result
    end
  end

end