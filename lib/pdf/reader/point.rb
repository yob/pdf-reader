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

    end
  end
end
