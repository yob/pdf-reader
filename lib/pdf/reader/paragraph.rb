# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader
    class Paragraph
      attr_reader :text, :origin

      def initialize(text, origin)
        @text = text
        @origin = origin
      end
    end
  end
end
