# coding: utf-8

module PDF
  module Preflight
    module Checks
      class NoEncryption
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
end
