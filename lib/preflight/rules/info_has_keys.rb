# coding: utf-8

module Preflight
  module Rules

    # ensure the info dict has the specified keys
    class InfoHasKeys

      def initialize(*keys)
        @keys = keys.flatten
      end

      def messages(ohash)
        info = ohash.object(ohash.trailer[:Info])
        missing = @keys - info.keys
        missing.map { |key|
          "Info dict missing required key #{key}"
        }
      end
    end
  end
end
