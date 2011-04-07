# coding: utf-8

module Preflight
  module Rules
    class NoEncryption

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
