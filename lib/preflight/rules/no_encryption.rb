# coding: utf-8

module Preflight
  module Rules
    class NoEncryption

      def self.rule_type
        :hash
      end

      def message(ohash)
        if ohash.trailer[:Encrypt]
          "File is encrypted"
        else
          nil
        end
      end
    end
  end
end
