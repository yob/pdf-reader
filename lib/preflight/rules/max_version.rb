# coding: utf-8

module Preflight
  module Rules
    # TODO: convert this to a more efficient ohash check
    class MaxVersion
      attr_reader :messages

      def initialize(max_version)
        @max_version = max_version.to_f
        @messages    = []
      end

      def self.rule_type
        :receiver
      end

      def pdf_version(arg = nil)
        if arg && arg > @max_version
          @messages << "PDF version should be #{@max_version} or lower (value: #{arg})"
        end
      end
    end
  end
end
