# coding: utf-8
#
module Marron
  module Filter # :nodoc:
    # implementation of the null stream filter
    class Null
      def initialize(options = {})
        @options = options
      end

      def filter(data)
        data
      end
    end
  end
end
