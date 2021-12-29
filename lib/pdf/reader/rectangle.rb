# coding: utf-8
# typed: strict
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

      attr_reader :bottom_left, :bottom_right, :top_left, :top_right

      def initialize(x1, y1, x2, y2)
        set_corners(x1, y1, x2, y2)
      end

      def self.from_array(arr)
        if arr.size != 4
          raise ArgumentError, "Only 4-element Arrays can be converted to a Rectangle"
        end

        PDF::Reader::Rectangle.new(
          arr[0].to_f,
          arr[1].to_f,
          arr[2].to_f,
          arr[3].to_f,
        )
      end

      def ==(other)
        to_a == other.to_a
      end

      def height
        top_right.y - bottom_right.y
      end

      def width
        bottom_right.x - bottom_left.x
      end

      def contains?(point)
        point.x >= bottom_left.x && point.x <= top_right.x &&
          point.y >= bottom_left.y && point.y <= top_right.y
      end

      # A pdf-style 4-number array
      def to_a
        [
          bottom_left.x,
          bottom_left.y,
          top_right.x,
          top_right.y,
        ]
      end

      def apply_rotation(degrees)
        return if degrees != 90 && degrees != 180 && degrees != 270

        if degrees == 90
          new_x1 = bottom_left.x
          new_y1 = bottom_left.y - width
          new_x2 = bottom_left.x + height
          new_y2 = bottom_left.y
        elsif degrees == 180
          new_x1 = bottom_left.x - width
          new_y1 = bottom_left.y - height
          new_x2 = bottom_left.x
          new_y2 = bottom_left.y
        elsif degrees == 270
          new_x1 = bottom_left.x - height
          new_y1 = bottom_left.y
          new_x2 = bottom_left.x
          new_y2 = bottom_left.y + width
        end
        set_corners(new_x1 || 0, new_y1 || 0, new_x2 || 0, new_y2 || 0)
      end

      private

      def set_corners(x1, y1, x2, y2)
        @bottom_left = PDF::Reader::Point.new(
          [x1, x2].min,
          [y1, y2].min,
        )
        @bottom_right = PDF::Reader::Point.new(
          [x1, x2].max,
          [y1, y2].min,
        )
        @top_left = PDF::Reader::Point.new(
          [x1, x2].min,
          [y1, y2].max,
        )
        @top_right = PDF::Reader::Point.new(
          [x1, x2].max,
          [y1, y2].max,
        )
      end
    end
  end
end
