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
    attr_reader :widths, :first_char, :ascent, :descent, :missing_width, :bbox
    attr_reader :basefont

    def initialize(ohash = nil, obj = nil)
      if ohash.nil? || obj.nil?
        $stderr.puts "DEPREACTION WARNING - PDF::Reader::Font.new should be called with 2 args"
        return
      end
      @ohash = ohash
      @tounicode = nil

      extract_base_info(obj)
      extract_descriptor(obj)
      extract_descendants(obj)

      @encoding ||= PDF::Reader::Encoding.new(:StandardEncoding)
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
      if @tounicode
        to_utf8_via_cmap(params)
      else
        to_utf8_via_encoding(params)
      end
    end

    def glyph_width(c)
      @missing_width ||= 0
      if @widths.nil?
        0
      else
        @widths.fetch(c.codepoints.first - @first_char, @missing_width)
      end
    end

    private

    def extract_base_info(obj)
      @subtype  = @ohash.object(obj[:Subtype])
      @basefont = @ohash.object(obj[:BaseFont])
      @encoding = PDF::Reader::Encoding.new(@ohash.object(obj[:Encoding]))
      @widths   = @ohash.object(obj[:Widths]) || []
      @first_char = @ohash.object(obj[:FirstChar])
      if obj[:ToUnicode]
        stream = @ohash.object(obj[:ToUnicode])
        @tounicode = PDF::Reader::CMap.new(stream.unfiltered_data)
      end
    end

    def extract_descriptor(obj)
      return unless obj[:FontDescriptor]

      fd       = @ohash.object(obj[:FontDescriptor])
      @ascent  = @ohash.object(fd[:Ascent])
      @descent = @ohash.object(fd[:Descent])
      @missing_width = @ohash.object(fd[:MissingWidth])
      @bbox    = @ohash.object(fd[:FontBBox])
    end

    def extract_descendants(obj)
      return unless obj[:DescendantFonts]

      descendants = @ohash.object(obj[:DescendantFonts])
      @descendantfonts = descendants.map { |desc|
        PDF::Reader::Font.new(@ohash, @ohash.object(desc))
      }
    end

    def to_utf8_via_cmap(params)
      if params.class == String
        params.unpack(encoding.unpack).map { |c|
          @tounicode.decode(c) || PDF::Reader::Encoding::UNKNOWN_CHAR
        }.pack("U*")
      elsif params.class == Array
        params.collect { |param| to_utf8_via_cmap(param) }
      else
        params
      end
    end

    def to_utf8_via_encoding(params)
      raise UnsupportedFeatureError, "font encoding '#{encoding}' currently unsupported" if encoding.kind_of?(String)

      if params.class == String
        encoding.to_utf8(params)
      elsif params.class == Array
        params.collect { |param| to_utf8_via_encoding(param) }
      else
        params
      end
    end

  end
end
