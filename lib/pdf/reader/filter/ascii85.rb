# coding: utf-8
# typed: true
# frozen_string_literal: true

require 'ascii85'

class PDF::Reader
  module Filter # :nodoc:
    # implementation of the Ascii85 filter
    class Ascii85
      extend T::Sig

      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data using the Ascii85 algorithm. Relies on the AScii85
      # rubygem.
      #
      sig {params(data: String).returns(String)}
      def filter(data)
        data = "<~#{data}" unless data.to_s[0,2] == "<~"
        if defined?(::Ascii85Native)
          ::Ascii85Native::decode(data)
        else
          ::Ascii85::decode(data)
        end
      rescue Exception => e
        # Oops, there was a problem decoding the stream
        raise MalformedPDFError,
          "Error occured while decoding an ASCII85 stream (#{e.class.to_s}: #{e.to_s})"
      end
    end
  end
end
