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
  class CMap # :nodoc:

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
      return nil if str.nil? || str.size == 0 || str.size >= 3

      if str.size == 1
        str.unpack("C*")[0]
      else
        str.unpack("n*")[0]
      end
    end

    def process_bfchar_instructions(instructions)
      parser  = build_parser(instructions)
      find    = str_to_int(parser.parse_token)
      replace = str_to_int(parser.parse_token)
      while find && replace
        @map[find] = replace
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
      start_code = str_to_int(start_code)
      end_code   = str_to_int(end_code)
      dst        = str_to_int(dst)

      # add all values in the range to our mapping
      (start_code..end_code).each_with_index do |val, idx|
        @map[val] = dst + idx
        # ensure a single range does not exceed 255 chars
        raise PDF::Reader::MalformedPDFError, "a CMap bfrange cann't exceed 255 chars" if idx > 255
      end
    end

    def bfrange_type_two(start_code, end_code, dst)
      start_code = str_to_int(start_code)
      end_code   = str_to_int(end_code)
      from_range = (start_code..end_code)

      # add all values in the range to our mapping
      from_range.each_with_index do |val, idx|
        @map[val] = str_to_int(dst[idx])
      end
    end
  end
end
