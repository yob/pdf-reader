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
  class Encoding # :nodoc:
    CONTROL_CHARS = [0,1,2,3,4,5,6,7,8,11,12,14,15,16,17,18,19,20,21,22,23,
                     24,25,26,27,28,29,30,31]
    UNKNOWN_CHAR = 0x25AF # ▯

    attr_reader :unpack

    def initialize(enc)
      if enc.kind_of?(Hash)
        self.differences = enc[:Differences] if enc[:Differences]
        enc = enc[:Encoding] || enc[:BaseEncoding]
      elsif enc != nil
        enc = enc.to_sym
      else
        enc = nil
      end

      @to_unicode_required = unicode_required?(enc)
      @unpack   = get_unpack(enc)
      @map_file = get_mapping_file(enc)
      load_mapping(@map_file) if @map_file
    end

    def to_unicode_required?
      @to_unicode_required
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
          byte += 1
        end
      end
      @differences
    end

    def differences
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
    def to_utf8(str, tounicode = nil)
      ret = str.unpack(unpack).map { |c|
        differences[c] || c
      }.map { |num|
        original_codepoint_to_unicode(num, tounicode)
      }.map { |c|
        glyphnames[c] || c
      }.map { |c|
        if c.nil? || !c.is_a?(Fixnum)
          PDF::Reader::Encoding::UNKNOWN_CHAR
        else
          c
        end
      }.pack("U*")

      ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

      ret
    end

    private

    def original_codepoint_to_unicode(cp, tounicode = nil)
      if tounicode && (code = tounicode.decode(cp))
        code
      elsif to_unicode_required? && (tounicode.nil? || tounicode.decode(cp).nil?)
        PDF::Reader::Encoding::UNKNOWN_CHAR
      elsif mapping[cp]
        mapping[cp]
      elsif PDF::Reader::Encoding::CONTROL_CHARS.include?(cp)
        PDF::Reader::Encoding::UNKNOWN_CHAR
      else
        cp
      end
    end

    def get_unpack(enc)
      case enc
      when :"Identity-H", :UTF16Encoding
        "n*"
      else
        "C*"
      end
    end

    def get_mapping_file(enc)
      return File.dirname(__FILE__) + "/encodings/standard.txt" if enc.nil?
      files = {
        :"Identity-H"      => nil,
        :MacRomanEncoding  => File.dirname(__FILE__) + "/encodings/mac_roman.txt",
        :MacExpertEncoding => File.dirname(__FILE__) + "/encodings/mac_expert.txt",
        :PDFDocEncoding    => File.dirname(__FILE__) + "/encodings/pdf_doc.txt",
        :StandardEncoding  => File.dirname(__FILE__) + "/encodings/standard.txt",
        :SymbolEncoding    => File.dirname(__FILE__) + "/encodings/symbol.txt",
        :UTF16Encoding     => nil,
        :WinAnsiEncoding   => File.dirname(__FILE__) + "/encodings/win_ansi.txt",
        :ZapfDingbatsEncoding => File.dirname(__FILE__) + "/encodings/zapf_dingbats.txt"
      }

      if files.has_key?(enc)
        files[enc]
      else
        raise UnsupportedFeatureError, "#{enc} is not currently a supported encoding"
      end
    end

    def unicode_required?(enc)
      enc == :"Identity-H"
    end

    def mapping
      @mapping ||= {}
    end

    def has_mapping?
      mapping.size > 0
    end

    def glyphnames
      @glyphnames ||= PDF::Reader::Font.glyphnames
    end

    def load_mapping(file)
      return if has_mapping?

      RUBY_VERSION >= "1.9" ? mode = "r:BINARY" : mode = "r"
      File.open(file, mode) do |f|
        f.each do |l|
          m, single_byte, unicode = *l.match(/([0-9A-Za-z]+);([0-9A-F]{4})/)
          mapping["0x#{single_byte}".hex] = "0x#{unicode}".hex if single_byte
        end
      end
    end

  end
end
