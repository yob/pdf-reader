# coding: utf-8
#
class PDF::Reader
  module Filter # :nodoc:
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
