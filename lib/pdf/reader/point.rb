# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader

    # PDFs are all about positioning content on a page, so there's lots of need to
    # work with a set of X,Y coordinates.
    #
    class Point

      #: Numeric
      attr_reader :x

      #: Numeric
      attr_reader :y

      #: (Numeric, Numeric) -> void
      def initialize(x, y)
        @x = x
        @y = y
      end

      #: (PDF::Reader::Point) -> bool
      def ==(other)
        other.respond_to?(:x) && other.respond_to?(:y) && x == other.x && y == other.y
      end

      # These two points are super common, so make them available as constants to reduce
      # object allocations. Points are immutable, so it's fine to have multiple code paths
      # using the same object
      ZERO_ZERO = self.new(0, 0) #: PDF::Reader::Point
      ONE_ONE = self.new(1, 1) #: PDF::Reader::Point

    end
  end
end
