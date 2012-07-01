# coding: utf-8
#
class PDF::Reader
  module Filter # :nodoc:
    class Ascii85
      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data using the Ascii85 algorithm. Relies on the AScii85
      # rubygem.
      #
      def filter(data)
        data = "<~#{data}" unless data.to_s[0,2] == "<~"
        ::Ascii85::decode(data)
      rescue Exception => e
        # Oops, there was a problem decoding the stream
        raise MalformedPDFError, "Error occured while decoding an ASCII85 stream (#{e.class.to_s}: #{e.to_s})"
      end
    end
  end
end
