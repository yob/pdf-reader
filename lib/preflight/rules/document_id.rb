# coding: utf-8

module Preflight
  module Rules
    class DocumentId

      def self.rule_type
        :hash
      end

      def messages(ohash)
        if ohash.trailer[:ID].nil?
          ["Document ID missing"]
        else
          []
        end
      end
    end
  end
end
