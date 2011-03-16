# coding: utf-8

module PDF
  module Preflight
    module Checks
      class DocumentId
        def message(ohash)
          if ohash.trailer[:ID].nil?
            "Document ID missing"
          else
            nil
          end
        end
      end
    end
  end
end
