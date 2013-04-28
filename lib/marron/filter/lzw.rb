# coding: utf-8
#
require 'marron/lzw'

module Marron
  module Filter # :nodoc:
    # implementation of the LZW stream filter
    class Lzw
      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data with the LZW compression algorithm
      def filter(data)
        data = Marron::LZW.decode(data)
        Depredict.new(@options).filter(data)
      end
    end
  end
end
