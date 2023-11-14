# coding: utf-8
# typed: true
# frozen_string_literal: true

module PDF
  class Reader

    # A simple class used by PDF::Reader::Page.paragraphs to represent a paragraph of text and its origin.
    class Paragraph
      attr_reader :text, :origin

      def initialize(text, origin)
        @text = text
        @origin = origin
      end
    end
  end
end
