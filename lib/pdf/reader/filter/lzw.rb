# coding: utf-8
# typed: true
# frozen_string_literal: true

#
class PDF::Reader
  module Filter # :nodoc:
    # implementation of the LZW stream filter
    class Lzw
      extend T::Sig

      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data with the LZW compression algorithm
      sig {params(data: String).returns(String)}
      def filter(data)
        data = PDF::Reader::LZW.decode(data)
        Depredict.new(@options).filter(data)
      end
    end
  end
end
