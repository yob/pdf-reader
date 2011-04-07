# coding: utf-8

module Preflight
  module Rules

    # All PDFX files MUST have an OutputConditionIdentifier entry in the
    # GTS_PDFX OutputIntent.
    #
    # This doesn't raise an error if there is no GTS_PDFX, that's another
    # rules job.
    #
    class PdfxOutputIntentHasOutputConditionIdentifier

      def self.rule_type
        :hash
      end

      def messages(ohash)
        oi = pdfx_output_intent(ohash)

        if oi && oi[:OutputConditionIdentifier].nil?
          ["The GTS_PDFX OutputIntent must have an OutputConditionIdentifier entry"]
        else
          []
        end
      end

      private

      def pdfx_output_intent(ohash)
        output_intents(ohash).map { |dict|
          ohash.object(dict)
        }.detect { |dict|
          dict[:S] == :GTS_PDFX
        }
      end

      def output_intents(ohash)
        root    = ohash.object(ohash.trailer[:Root])
        intents = ohash.object(root[:OutputIntents])
        intents || []
      end

    end
  end
end
