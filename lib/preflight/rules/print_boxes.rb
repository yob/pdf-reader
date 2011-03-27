# coding: utf-8

module Preflight
  module Rules

    # For PDFX/1a, every page must have MediaBox, plus either ArtBox or
    # TrimBox
    #
    class PrintBoxes
      attr_reader :messages

      def initialize
        @messages = []
      end

      def self.rule_type
        :receiver
      end

      def begin_page(hash = {})
        if hash[:MediaBox].nil?
          @messages << "every page must have a MediaBox"
        elsif hash[:ArtBox].nil? && hash[:TrimBox].nil?
          @messages << "every page must have either an ArtBox or a TrimBox"
        elsif hash[:ArtBox] && hash[:TrimBox]
          @messages << "no page can have both ArtBox and TrimBox (TrimBox is preferred)"
        end
      end
    end
  end
end
