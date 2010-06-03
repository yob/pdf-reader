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
  class Font
    attr_accessor :label, :subtype, :encoding, :descendantfonts, :tounicode
    attr_reader :basefont

    # returns a hash that maps glyph names to unicode codepoints. The mapping is based on
    # a text file supplied by Adobe at:
    # http://www.adobe.com/devnet/opentype/archives/glyphlist.txt
    def self.glyphnames
      glyphs = {}

      RUBY_VERSION >= "1.9" ? mode = "r:BINARY" : mode = "r"
      File.open(File.dirname(__FILE__) + "/glyphlist.txt",mode) do |f|
        f.each do |l|
          m, name, code = *l.match(/([0-9A-Za-z]+);([0-9A-F]{4})/)
          glyphs[name.to_sym] = "0x#{code}".hex if name
        end
      end

      glyphs
    end

    def basefont=(font)
      # setup a default encoding for the selected font. It can always be overridden
      # with encoding= if required
      case font
      when "Symbol" then
        @encoding = PDF::Reader::Encoding.new("SymbolEncoding")
      when "ZapfDingbats" then
        @encoding = PDF::Reader::Encoding.new("ZapfDingbatsEncoding")
      else
        @encoding = nil
      end
      @basefont = font
    end

    def to_utf8(params)
      raise UnsupportedFeatureError, "font encoding '#{encoding}' currently unsupported" if encoding.kind_of?(String)

      if params.class == String
        # translate the bytestram into a UTF-8 string.
        # If an encoding hasn't been specified, assume the text using this
        # font is in Adobe Standard Encoding.
        (encoding || PDF::Reader::Encoding.new(:StandardEncoding)).to_utf8(params, tounicode)
      elsif params.class == Array
        params.collect { |param| self.to_utf8(param) }
      else
        params
      end
    end
  end
end
