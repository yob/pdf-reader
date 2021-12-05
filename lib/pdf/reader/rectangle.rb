# coding: utf-8
# typed: true
# frozen_string_literal: true

module PDF
  class Reader

    # PDFs represent rectangles all over the place. They're 4 element arrays, like this:
    #
    #     [A, B, C, D]
    #
    # Four element arrays are yucky to work with though, so here's a class that's better.
    # Initialize it with the 4 elements, and get utility functions (width, height, etc)
    # for free.
    #
    # By convention the first two elements are x1, y1, the co-ords for the bottom left corner
    # of the rectangle. The third and fourth elements are x2, y2, the co-ords for the top left
    # corner of the rectangle. It's valid for the alternative corners to be used though, so
    # we don't assume which is which.
    #
    class Rectangle
      def initialize(x1, y1, x2, y2)
        @x1, @y1, @x2, @y2 = x1, y1, x2, y2
      end

      def bottom_left
        [
          [@x1, @x2].min,
          [@y1, @y2].min,
        ]
      end

      def bottom_right
        [
          [@x1, @x2].max,
          [@y1, @y2].min,
        ]
      end

      def top_left
        [
          [@x1, @x2].min,
          [@y1, @y2].max,
        ]
      end

      def top_right
        [
          [@x1, @x2].max,
          [@y1, @y2].max,
        ]
      end

      def height
        top_right[1] - bottom_right[1]
      end

      def width
        bottom_right[0] - bottom_left[0]
      end

      def apply_rotation(degrees)
        return if degrees != 90 && degrees != 180 && degrees != 270

        if degrees == 90
          new_x1 = @x1
          new_y1 = @y1 - width
          new_x2 = @x1 + height
          new_y2 = @y1
        elsif degrees == 180
          new_x1 = @x1 - width
          new_y1 = @y1 - height
          new_x2 = @x1
          new_y2 = @y1
        elsif degrees == 270
          new_x1 = @x1 - height
          new_y1 = @y1
          new_x2 = @x1
          new_y2 = @y1 + width
        end
        @x1 = new_x1
        @y1 = new_y1
        @x2 = new_x2
        @y2 = new_y2
      end
    end
  end
end
