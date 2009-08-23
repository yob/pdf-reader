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

require 'enumerator'

class PDF::Reader
  class Encoding

    UNKNOWN_CHAR = 0x25AF # ▯

    attr_reader :differences

    def initialize(enc)
      if enc.kind_of?(Hash)
        self.differences=enc[:Differences] if enc[:Differences]
        enc = enc[:Encoding] || enc[:BaseEncoding]
      elsif enc != nil
        enc = enc.to_sym
      end

      case enc
        when nil                   then
          load_mapping File.dirname(__FILE__) + "/encodings/standard.txt"
          @unpack = "C*"
        when "Identity-H".to_sym   then
          @unpack = "n*"
          @to_unicode_required = true
        when :MacRomanEncoding     then
          load_mapping File.dirname(__FILE__) + "/encodings/mac_roman.txt"
          @unpack = "C*"
        when :MacExpertEncoding    then
          load_mapping File.dirname(__FILE__) + "/encodings/mac_expert.txt"
          @unpack = "C*"
        when :PDFDocEncoding       then
          load_mapping File.dirname(__FILE__) + "/encodings/pdf_doc.txt"
          @unpack = "C*"
        when :StandardEncoding     then
          load_mapping File.dirname(__FILE__) + "/encodings/standard.txt"
          @unpack = "C*"
        when :SymbolEncoding       then
          load_mapping File.dirname(__FILE__) + "/encodings/symbol.txt"
          @unpack = "C*"
        when :UTF16Encoding        then
          @unpack = "n*"
        when :WinAnsiEncoding      then
          load_mapping File.dirname(__FILE__) + "/encodings/win_ansi.txt"
          @unpack = "C*"
        when :ZapfDingbatsEncoding then
          load_mapping File.dirname(__FILE__) + "/encodings/zapf_dingbats.txt"
          @unpack = "C*"
        else raise UnsupportedFeatureError, "#{enc} is not currently a supported encoding"
      end
    end

    # set the differences table for this encoding. should be an array in the following format:
    #
    #   [25, :A, 26, :B]
    #
    # The array alternates bewteen a decimal byte number and a glyph name to map to that byte
    #
    # To save space the following array is also valid and equivilant to the previous one
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
          byte += 1
        end
      end
      @differences
    end

    # convert the specified string to utf8
    def to_utf8(str, tounicode = nil)

      # unpack the single bytes
      array_orig = str.unpack(@unpack)

      # replace any relevant bytes with a glyph name
      array_orig = process_differences(array_orig)

      # replace any remaining bytes with a unicode codepoint
      array_enc = []
      array_orig.each do |num|
        if tounicode && (code = tounicode.decode(num))
          array_enc << code
        elsif tounicode || (tounicode.nil? && @to_unicode_required)
          array_enc << PDF::Reader::Encoding::UNKNOWN_CHAR
        elsif @mapping && @mapping[num]
          array_enc << @mapping[num]
        else
          array_enc << num
        end
      end

      # convert any glyph names to unicode codepoints
      array_enc = process_glyphnames(array_enc)

      # replace charcters that didn't convert to unicode nicely with something valid
      array_enc.collect! { |c| c ? c : PDF::Reader::Encoding::UNKNOWN_CHAR }

      # pack all our Unicode codepoints into a UTF-8 string
      ret = array_enc.pack("U*")

      # set the strings encoding correctly under ruby 1.9+
      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

      return ret
    end

    private

    # accepts an array of byte numbers, and replaces any that have entries in the differences table
    # with a glyph name
    def process_differences(arr)
      @differences ||= {}
      arr.collect! { |n| @differences[n].nil? ? n : @differences[n]}
    end

    # accepts an array of unicode code points and glyphnames, and converts any glyph names to codepoints
    def process_glyphnames(arr)
      @differences ||= {}
      arr.collect! { |n| n.kind_of?(Numeric) ? n : PDF::Reader::Font.glyphnames[n]}
    end

    def load_mapping(file)
      @mapping = {}
      RUBY_VERSION >= "1.9" ? mode = "r:BINARY" : mode = "r"
      File.open(file, mode) do |f|
        f.each do |l|
          m, single_byte, unicode = *l.match(/([0-9A-Za-z]+);([0-9A-F]{4})/)
          @mapping["0x#{single_byte}".hex] = "0x#{unicode}".hex if single_byte
        end
      end
    end

  end
end
