# coding: utf-8
# frozen_string_literal: true


require 'zlib'

class PDF::Reader
  module Filter # :nodoc:
    # implementation of the Flate (zlib) stream filter
    class Flate
      ZLIB_AUTO_DETECT_ZLIB_OR_GZIP = 47  # Zlib::MAX_WBITS + 32
      ZLIB_RAW_DEFLATE              = -15 # Zlib::MAX_WBITS * -1

      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data with the Zlib compression algorithm
      def filter(data)
        deflated = zlib_inflate(data) || zlib_inflate(data[0, data.bytesize-1])

        if deflated.nil?
          raise MalformedPDFError,
            "Error while inflating a compressed stream (no suitable inflation algorithm found)"
        end
        Depredict.new(@options).filter(deflated)
      end

      private

      def zlib_inflate(data)
        begin
          return Zlib::Inflate.new(ZLIB_AUTO_DETECT_ZLIB_OR_GZIP).inflate(data)
        rescue Zlib::DataError => e
          # by default, Ruby's Zlib assumes the data it's inflating
          # is RFC1951 deflated data, wrapped in a RFC1950 zlib container. If that
          # fails, swallow the exception and attempt to inflate the data as a raw
          # RFC1951 stream.
        end

        begin
          return Zlib::Inflate.new(ZLIB_RAW_DEFLATE).inflate(data)
        rescue StandardError => e
          # swallow this one too, so we can try some other fallback options
        end

        nil
      end
    end
  end
end

