# coding: utf-8

module Preflight
  module Rules

    # ensure the root dict has the specified keys
    class RootHasKeys

      def initialize(*keys)
        @keys = keys.flatten
      end

      def self.rule_type
        :hash
      end

      def messages(ohash)
        root = ohash.object(ohash.trailer[:Root])
        missing = @keys - root.keys
        if missing.size > 0
          ["Root dict missing required keys (#{missing.join(", ")})"]
        else
          []
        end
      end
    end
  end
end
