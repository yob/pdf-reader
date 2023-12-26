# coding: utf-8
# typed: true
# frozen_string_literal: true

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

    CMAP_KEYWORDS = {
      "begincodespacerange" => :noop,
      "endcodespacerange" => :noop,
      "beginbfchar" => :noop,
      "endbfchar" => :noop,
      "beginbfrange" => :noop,
      "endbfrange" => :noop,
      "begin" => :noop,
      "begincmap" => :noop,
      "def" => :noop
    }

    attr_reader :map

    def initialize(data)
      @map = {}
      process_data(data)
    end

    def size
      @map.size
    end

    # Convert a glyph code into one or more Codepoints.
    #
    # Returns an array of Integers.
    #
    def decode(c)
      @map.fetch(c, [])
    end

    private

    def process_data(data, initial_mode = :none)
      parser = build_parser(data)
      mode = initial_mode
      instructions = []

      while token = parser.parse_token(CMAP_KEYWORDS)
        if token.is_a?(String) || token.is_a?(Array)
          if token == "beginbfchar"
            mode = :char
          elsif token == "endbfchar"
            process_bfchar_instructions(instructions)
            instructions = []
            mode = :none
          elsif token == "beginbfrange"
            mode = :range
          elsif token == "endbfrange"
            process_bfrange_instructions(instructions)
            instructions = []
            mode = :none
          elsif mode == :char
            instructions << token.to_s
          elsif mode == :range
            instructions << token
          end
        end
      end
    end


    def build_parser(instructions)
      buffer = Buffer.new(StringIO.new(instructions))
      Parser.new(buffer)
    end

    # The following includes some manual decoding of UTF-16BE strings into unicode codepoints. In
    # theory we could replace all the UTF-16 code with something based on Ruby's encoding support:
    #
    #    str.dup.force_encoding("utf-16be").encode!("utf-8").unpack("U*")
    #
    # However, some cmaps contain broken surrogate pairs and the ruby encoding support raises an
    # exception when we try converting broken UTF-16 to UTF-8
    #
    def str_to_int(str)
      unpacked_string = if str.bytesize == 1 # UTF-8
        str.unpack("C*")
      else # UTF-16
         str.unpack("n*")
      end
      result = []
      while unpacked_string.any? do
        if unpacked_string.size >= 2 &&
            unpacked_string.first.to_i >= 0xD800 &&
            unpacked_string.first.to_i <= 0xDBFF
          # this is a Unicode UTF-16 "Surrogate Pair" see Unicode Spec. Chapter 3.7
          # lets convert to a UTF-32. (the high bit is between 0xD800-0xDBFF, the
          # low bit is between 0xDC00-0xDFFF) for example: U+1D44E (U+D835 U+DC4E)
          point_one = unpacked_string.shift.to_i
          point_two = unpacked_string.shift.to_i
          result << (point_one - 0xD800) * 0x400 + (point_two - 0xDC00) + 0x10000
        else
          result << unpacked_string.shift
        end
      end
      result
    end

    def process_bfchar_instructions(instructions)
      instructions.each_slice(2) do |one, two|
        find    = str_to_int(one.to_s)
        replace = str_to_int(two.to_s)
        if find.any? && replace.any?
          @map[find.first.to_i] = replace
        end
      end
    end

    def process_bfrange_instructions(instructions)
      instructions.each_slice(3) do |start, finish, to|
        if start.kind_of?(String) && finish.kind_of?(String) && to.kind_of?(String)
          bfrange_type_one(start, finish, to)
        elsif start.kind_of?(String) && finish.kind_of?(String) && to.kind_of?(Array)
          bfrange_type_two(start, finish, to)
        else
          raise MalformedPDFError, "invalid bfrange section"
        end
      end
    end

    def bfrange_type_one(start_code, end_code, dst)
      start_code = str_to_int(start_code).first
      end_code   = str_to_int(end_code).first
      dst        = str_to_int(dst)

      return if start_code.nil? || end_code.nil?

      # add all values in the range to our mapping
      (start_code..end_code).each_with_index do |val, idx|
        @map[val] = dst.length == 1 ? [dst[0].to_i + idx] : [dst[0].to_i, dst[1].to_i + 1]
      end
    end

    def bfrange_type_two(start_code, end_code, dst)
      start_code = str_to_int(start_code).first
      end_code   = str_to_int(end_code).first

      return if start_code.nil? || end_code.nil?

      from_range = (start_code..end_code)

      # add all values in the range to our mapping
      from_range.each_with_index do |val, idx|
        dst_char = dst[idx]
        @map[val.to_i] = str_to_int(dst_char) if dst_char
      end
    end
  end
end
