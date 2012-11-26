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
  # Util class for working with string encodings in PDF files. Mostly used to
  # convert strings of various PDF-dialect encodings into UTF-8.
  class Encoding # :nodoc:
    CONTROL_CHARS = [0,1,2,3,4,5,6,7,8,11,12,14,15,16,17,18,19,20,21,22,23,
                     24,25,26,27,28,29,30,31]
    UNKNOWN_CHAR = 0x25AF # ▯

    attr_reader :unpack

    def initialize(enc)
      @mapping  = {} # maps from character codes to Unicode codepoints
                     # also maps control and invalid chars to UNKNOWN_CHAR
      @string_cache  = {} # maps from character codes to UTF-8 strings.

      if enc.kind_of?(Hash)
        self.differences = enc[:Differences] if enc[:Differences]
        enc = enc[:Encoding] || enc[:BaseEncoding]
      elsif enc != nil
        enc = enc.to_sym
      else
        enc = nil
      end

      @enc_name = enc
      @unpack   = get_unpack(enc)
      @map_file = get_mapping_file(enc)

      load_mapping(@map_file) if @map_file
      add_control_chars_to_mapping
    end

    # set the differences table for this encoding. should be an array in the following format:
    #
    #   [25, :A, 26, :B]
    #
    # The array alternates between a decimal byte number and a glyph name to map to that byte
    #
    # To save space the following array is also valid and equivalent to the previous one
    #
    #   [25, :A, :B]
    def differences=(diff)
      raise ArgumentError, "diff must be an array" unless diff.kind_of?(Array)

      @differences = {}
      byte = 0
      diff.each do |val|
        if val.kind_of?(Numeric)
          byte = val.to_i
        else
          @differences[byte] = val
          @mapping[byte] = names_to_unicode[val]
          byte += 1
        end
      end
      @differences
    end

    def differences
      # this method is only used by the spec tests
      @differences ||= {}
    end

    # convert the specified string to utf8
    #
    # * unpack raw bytes into codepoints
    # * replace any that have entries in the differences table with a glyph name
    # * convert codepoints from source encoding to Unicode codepoints
    # * convert any glyph names to Unicode codepoints
    # * replace characters that didn't convert to Unicode nicely with something
    #   valid
    # * pack the final array of Unicode codepoints into a utf-8 string
    # * mark the string as utf-8 if we're running on a M17N aware VM
    #
    def to_utf8(str)
      if utf8_conversion_impossible?
        little_boxes(str.unpack(unpack).size)
      else
        convert_to_utf8(str)
      end
    end

    def int_to_utf8_string(glyph_code)
      @string_cache[glyph_code] ||= internal_int_to_utf8_string(glyph_code)
    end

    # convert an integer glyph code into an Adobe glyph name.
    #
    #     int_to_name(65)
    #     => :A
    #
    # TODO: this needs to be expanded to return the appropriate name for standard
    #       glyph codes in the encoding. 65 to :A, etc. At the moment it only
    #       handles glyphs in the difference table
    #
    def int_to_name(glyph_code)
      if @enc_name == "Identity-H" || @enc_name == "Identity-V"
        nil
      else
        @differences[glyph_code]
      end
    end

    private

    def internal_int_to_utf8_string(glyph_code)
      ret = [
        @mapping[glyph_code.to_i] || glyph_code.to_i
      ].pack("U*")
      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)
      ret
    end

    def utf8_conversion_impossible?
      @enc_name == :"Identity-H" || @enc_name == :"Identity-V"
    end

    def little_boxes(times)
      codepoints = [ PDF::Reader::Encoding::UNKNOWN_CHAR ] * times
      ret = codepoints.pack("U*")
      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)
      ret
    end

    def convert_to_utf8(str)
      ret = str.unpack(unpack).map! { |c| @mapping[c] || c }.pack("U*")
      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)
      ret
    end

    def get_unpack(enc)
      case enc
      when :"Identity-H", :"Identity-V", :UTF16Encoding
        "n*"
      else
        "C*"
      end
    end

    def get_mapping_file(enc)
      case enc
      when :"Identity-H", :"Identity-V", :UTF16Encoding then
        nil
      when :MacRomanEncoding then
        File.dirname(__FILE__) + "/encodings/mac_roman.txt"
      when :MacExpertEncoding then
        File.dirname(__FILE__) + "/encodings/mac_expert.txt"
      when :PDFDocEncoding then
        File.dirname(__FILE__) + "/encodings/pdf_doc.txt"
      when :SymbolEncoding then
        File.dirname(__FILE__) + "/encodings/symbol.txt"
      when :WinAnsiEncoding then
        File.dirname(__FILE__) + "/encodings/win_ansi.txt"
      when :ZapfDingbatsEncoding then
        File.dirname(__FILE__) + "/encodings/zapf_dingbats.txt"
      else
        File.dirname(__FILE__) + "/encodings/standard.txt"
      end
    end

    def has_mapping?
      @mapping.size > 0
    end

    def names_to_unicode
      @names_to_unicode ||= PDF::Reader::GlyphHash.new
    end

    def load_mapping(file)
      return if has_mapping?

      RUBY_VERSION >= "1.9" ? mode = "r:BINARY" : mode = "r"
      File.open(file, mode) do |f|
        f.each do |l|
          m, single_byte, unicode = *l.match(/([0-9A-Za-z]+);([0-9A-F]{4})/)
          @mapping["0x#{single_byte}".hex] = "0x#{unicode}".hex if single_byte
        end
      end
    end

    def add_control_chars_to_mapping
      PDF::Reader::Encoding::CONTROL_CHARS.each do |byte|
        unless @mapping[byte]
          @mapping[byte] = PDF::Reader::Encoding::UNKNOWN_CHAR
        end
      end
      @mapping[nil] = PDF::Reader::Encoding::UNKNOWN_CHAR
    end
  end
end
