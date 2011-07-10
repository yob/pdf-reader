# coding: utf-8

module Preflight
  module Rules
    class DocumentId

      def check_hash(ohash)
        if ohash.trailer[:ID].nil?
          ["Document ID missing"]
        else
          []
        end
      end
    end
  end
end
