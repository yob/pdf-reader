# coding: utf-8

module Preflight
  module Rules

    # ensure the root dict has the specified keys
    class RootHasKeys

      def initialize(*keys)
        @keys = keys.flatten
      end

      def check_hash(ohash)
        root = ohash.object(ohash.trailer[:Root])
        missing = @keys - root.keys
        missing.map { |key|
          "Root dict missing required key #{key}"
        }
      end
    end
  end
end
