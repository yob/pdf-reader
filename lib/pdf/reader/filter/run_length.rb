# coding: utf-8
# typed: true
# frozen_string_literal: true

#
class PDF::Reader # :nodoc:
  module Filter # :nodoc:
    # implementation of the run length stream filter
    class RunLength
      extend T::Sig

      def initialize(options = {})
        @options = options
      end

      ################################################################################
      # Decode the specified data with the RunLengthDecode compression algorithm
      sig {params(data: String).returns(String)}
      def filter(data)
        pos = 0
        out = "".dup

        while pos < data.length
          length = data.getbyte(pos)
          pos += 1

          unless length.nil?
            case
              # nothing
            when length == 128
              break
            when length < 128
              # When the length is < 128, we copy the following length+1 bytes
              # literally.
              out << data[pos, length + 1]
              pos += length
            else
              # When the length is > 128, we copy the next byte (257 - length)
              # times; i.e., "\xFA\x00" ([250, 0]) will expand to
              # "\x00\x00\x00\x00\x00\x00\x00".
              previous_byte = data[pos, 1] || ""
              out << previous_byte * (257 - length)
            end
          end

          pos += 1
        end

        Depredict.new(@options).filter(out)
      end
    end
  end
end
