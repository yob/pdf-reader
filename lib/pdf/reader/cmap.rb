# coding: utf-8

################################################################################
#
# Copyright (C) 2008 James Healy (jimmy@deefa.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################

class PDF::Reader

  # wraps a string containing a PDF CMap and provides convenience methods for
  # extracting various useful information.
  #
  class CMap # :nodoc:

    attr_reader :map

    def initialize(data)
      @map = {}
      process_data(data)
    end

    def process_data(data)
      mode = nil
      instructions = ""

      data.each_line do |l|
        if l.include?("beginbfchar")
          mode = :char
        elsif l.include?("endbfchar")
          process_bfchar_instructions(instructions)
          instructions = ""
          mode = nil
        elsif l.include?("beginbfrange")
          mode = :range
        elsif l.include?("endbfrange")
          process_bfrange_instructions(instructions)
          instructions = ""
          mode = nil
        elsif mode == :char || mode == :range
          instructions << l
        end
      end
    end

    def size
      @map.size
    end

    # Convert a glyph code into one or more Codepoints.
    #
    # Returns an array of Fixnums.
    #
    def decode(c)
      # TODO: implement the conversion
      return c unless c.class == Fixnum
      @map[c]
    end

    private

    def build_parser(instructions)
      buffer = Buffer.new(StringIO.new(instructions))
      Parser.new(buffer)
    end

    def str_to_int(str)
      return nil if str.nil? || str.size == 0
      unpacked_string = if str.size == 1 # UTF-8
        str.unpack("C*")
      else # UTF-16
         str.unpack("n*")
      end
      if unpacked_string.size == 1
        unpacked_string
      elsif unpacked_string.size == 2 && unpacked_string[0] > 0xD800 && unpacked_string[0] < 0xDBFF
        # this is a Unicode UTF-16 "Surrogate Pair" see Unicode Spec. Chapter 3.7
        # lets convert to a UTF-32. (the high bit is between 0xD800-0xDBFF, the
        # low bit is between 0xDC00-0xDFFF) for example: U+1D44E (U+D835 U+DC4E)
        [(unpacked_string[0] - 0xD800) * 0x400 + (unpacked_string[1] - 0xDC00) + 0x10000]
      else
        # it is a bad idea to just return the first 16 bits, as this doesn't allow
        # for ligatures for example fi (U+0066 U+0069)
        unpacked_string
      end
    end

    def process_bfchar_instructions(instructions)
      parser  = build_parser(instructions)
      find    = str_to_int(parser.parse_token)
      replace = str_to_int(parser.parse_token)
      while find && replace
        @map[find[0]] = replace
        find       = str_to_int(parser.parse_token)
        replace    = str_to_int(parser.parse_token)
      end
    end

    def process_bfrange_instructions(instructions)
      parser  = build_parser(instructions)
      start   = parser.parse_token
      finish  = parser.parse_token
      to      = parser.parse_token
      while start && finish && to
        if start.kind_of?(String) && finish.kind_of?(String) && to.kind_of?(String)
          bfrange_type_one(start, finish, to)
        elsif start.kind_of?(String) && finish.kind_of?(String) && to.kind_of?(Array)
          bfrange_type_two(start, finish, to)
        else
          raise "invalid bfrange section"
        end
        start   = parser.parse_token
        finish  = parser.parse_token
        to      = parser.parse_token
      end
    end

    def bfrange_type_one(start_code, end_code, dst)
      start_code = str_to_int(start_code)[0]
      end_code   = str_to_int(end_code)[0]
      dst        = str_to_int(dst)

      # add all values in the range to our mapping
      (start_code..end_code).each_with_index do |val, idx|
        @map[val] = dst.length == 1 ? [dst[0] + idx] : [dst[0], dst[1] + 1]
      end
    end

    def bfrange_type_two(start_code, end_code, dst)
      start_code = str_to_int(start_code)[0]
      end_code   = str_to_int(end_code)[0]
      from_range = (start_code..end_code)

      # add all values in the range to our mapping
      from_range.each_with_index do |val, idx|
        @map[val] = str_to_int(dst[idx])
      end
    end
  end
end
