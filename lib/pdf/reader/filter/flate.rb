# coding: utf-8
# frozen_string_literal: true


require 'zlib'

class PDF::Reader
  module Filter # :nodoc:
    # implementation of the Flate (zlib) stream filter
    class Flate
      ZLIB_AUTO_DETECT_ZLIB_OR_GZIP = 47  # Zlib::MAX_WBITS + 32

      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data with the Zlib compression algorithm
      def filter(data)
        deflated = nil
        begin
          deflated = Zlib::Inflate.new(ZLIB_AUTO_DETECT_ZLIB_OR_GZIP).inflate(data)
        rescue Zlib::DataError => e
          # by default, Ruby's Zlib assumes the data it's inflating
          # is RFC1951 deflated data, wrapped in a RFC1950 zlib container. If that
          # fails, then use a lightly-documented 'feature' to attempt to inflate
          # the data as a raw RFC1951 stream.
          #
          # See
          # - http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/243545
          deflated = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(data)
        end
        Depredict.new(@options).filter(deflated)
      rescue Exception => e
        # Oops, there was a problem inflating the stream
        raise MalformedPDFError,
          "Error occured while inflating a compressed stream (#{e.class.to_s}: #{e.to_s})"
      end
    end
  end
end

