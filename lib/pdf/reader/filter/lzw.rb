# coding: utf-8
# typed: strict
# frozen_string_literal: true

#
class PDF::Reader
  module Filter # :nodoc:
    # implementation of the LZW stream filter
    class Lzw

      #: (?Hash[untyped, untyped]) -> void
      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data with the LZW compression algorithm
      #: (String) -> String
      def filter(data)
        data = PDF::Reader::LZW.decode(data)
        Depredict.new(@options).filter(data)
      end
    end
  end
end
