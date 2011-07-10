# coding: utf-8

module Preflight
  module Rules
    class NoEncryption

      def check_hash(ohash)
        if ohash.trailer[:Encrypt]
          ["File is encrypted"]
        else
          []
        end
      end
    end
  end
end
