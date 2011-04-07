# coding: utf-8

module Preflight
  module Rules

    # For each page MediaBox must be the biggest box, followed by the
    # BleedBox or ArtBox, followed by the TrimBox.
    #
    class OutputIntentForPdfx

      def self.rule_type
        :hash
      end

      def messages(ohash)
        intents = output_intents(ohash).select { |dict|
          dict[:S] == :GTS_PDFX
        }

        if intents.size != 1
          ["There must be exactly 1 OutputIntent with a subtype of GTS_PDFX"]
        else
          []
        end
      end

      private

      def output_intents(ohash)
        root    = ohash.object(ohash.trailer[:Root])
        intents = ohash.object(root[:OutputIntents])
        intents || []
      end

    end
  end
end
