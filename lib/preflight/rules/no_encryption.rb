# coding: utf-8

module Preflight
  module Rules
    class NoEncryption

      def self.rule_type
        :hash
      end

      def messages(ohash)
        if ohash.trailer[:Encrypt]
          ["File is encrypted"]
        else
          []
        end
      end
    end
  end
end
