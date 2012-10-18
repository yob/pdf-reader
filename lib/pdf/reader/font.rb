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
  # Represents a single font PDF object and provides some useful methods
  # for extracting info. Mainly used for converting text to UTF-8.
  #
  class Font
    attr_accessor :subtype, :encoding, :descendantfonts, :tounicode
    attr_reader :widths, :first_char, :last_char, :basefont, :font_descriptor,
                :is_cid_type, :is_ttyp_type, :cid_widths, :cid_default_width,
                :has_to_unicode_table, :DEBUG_FONT

    def initialize(ohash = nil, obj = nil)
      if ohash.nil? || obj.nil?
        $stderr.puts "DEPREACTION WARNING - PDF::Reader::Font.new should be called with 2 args"
        return
      end
      @ohash = ohash
      @tounicode = nil
      @DEBUG_FONT = 0

      extract_base_info(obj)
      extract_descriptor(obj)
      extract_descendants(obj)

      @encoding ||= PDF::Reader::Encoding.new(:StandardEncoding)
      puts "##### Finished Reading: #{@basefont}" if @DEBUG_FONT > 0
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

    def can_convert_to_utf8?
      (@tounicode && @tounicode.map.count > 0) || @encoding
    end

    def to_utf8(params)
      if @tounicode
        to_utf8_via_cmap(params)
      else
        to_utf8_via_encoding(params)
      end
    end

    # breaks apart the specified fragment into it's codepoints and sums all codepoint
    # widths, returing a width specified in text space units, the given should be
    # the raw (encoded) fragment, not the converted utf-8 fragment provided by the
    # to_utf8 method
    def width_of_fragment(fragment)
      if can_convert_to_utf8?
        if fragment.class == String
          frag_width = fragment.unpack(encoding.unpack).inject(0) { |width, c|
            gw = glyph_width(c)
            $stderr.puts "Unexpected width received for character: #{c}" if gw.nil?
            width += gw unless gw.nil?
          }
          return frag_width / 1000.0 if frag_width
        end
      else
        $stderr.puts "can't convert this fragment ('#{fragment}') to unicode " +
          "(glyphs exist, but I don't know what they represent)"
      end
    end

    # looks up the specified codepoint and returns a value that is in (pdf)
    # glyph space, which is 1000 glyph units = 1 text space unit
    def glyph_width(code_point)
      @cached_widths ||= {}
      @cached_widths[code_point] ||= internal_glyph_width(code_point)
    end

    private

    def internal_glyph_width(code_point)
      return 0 if code_point.nil? || code_point < 0

      puts "glyph_width(#{code_point})" if @DEBUG_FONT > 2

      # Type0 (or Composite) fonts are a "root font" that rely on a "descendant font"
      # to do the heavy lifting. The "descendant font" is a CID-Keyed font.
      # see Section 9.7.1, PDF 32000-1:2008, pp 267
      # so if we are calculating a Type0 font width, we just pass off to
      # the descendant font
      if @subtype == :Type0
        if descendant_font = @descendantfonts[0]
          #DEBUG puts "Calculating type 0 font with descendant font"
          if w = descendant_font.glyph_width(code_point)
            puts "Got Type0 font width from descendant font Width: #{w}"if @DEBUG_FONT > 1
            return w.to_f
          end
        end
      end

      # CIDFontType0 or CIDFontType2 use DW (integer) and W (array) to determine
      # codepoint widths, note that CIDFontType2 will contain a true type font
      # program which could be used to calculate width, however, a conforming writer
      # is supposed to convert the widths for the codepoints used into the W array
      # so that it can be used.
      # see Section 9.7.4.1, PDF 32000-1:2008, pp 269-270
      if @is_cid_typ
        w = calculate_cidfont_glyph_width(code_point)
        puts "calculate_cidfont_glyph_width('#{code_point}') = #{w}" if @DEBUG_FONT > 0
        # 0 is a valid width
        return w.to_f unless w.nil?
      end

      # Type1 and Type3 fonts use a Width table, any value not in the width
      # table is assumed to be 0 (Type3) or defined in the font_descriptor[MissingWidth]
      # (Type1). For Type1, these values are always 1000 glyph units = 1 text space unit.
      # For Type3 the scale is found in FontMatrix, although, commonly 1000 glyph units =
      # 1 text space unit ([0.001 0 0 0.001 0 0]) is used.
      # see Section 9.6.2.1 PDF 32000-1:2008 pp 254-255 (Type1)
      # see Section 9.6.5 PDF 32000-1:2008 pp 258-259 (Type3)
      if @widths && @widths.count > 0
        $stderr.puts "Problem with font (#{@basefont}), no first_char reference" if @first_char.nil?
        missing_width = @font_descriptor ? @font_descriptor.missing_width : 0
        if @first_char <= code_point
          # in ruby a negative index is valid, and will go from the end of the array
          # which is undesireable in this case.
          w = @widths.fetch(code_point - @first_char, missing_width)
        else
          w = missing_width
        end
        #TODO convert Type3 units 1000 units => 1 text space unit
        puts "Widths['#{code_point}'] = #{w}" if @DEBUG_FONT > 0
        return w.to_f
      end

      puts "Font Descriptor: #{@font_descriptor.inspect}" if @DEBUG_FONT > 2
      # if all else fails revert to the font descriptor
      return unless @font_descriptor
      # true type fonts will have most of their information contained
      # with-in a program inside the font descriptor, however the widths
      # may not be in standard PDF glyph widths (1000 units => 1 text space unit)
      # so this width will need to be scaled
      w = @font_descriptor.find_glyph_width(code_point)
      puts "font_descriptor.find_glyph_width(#{code_point}) = #{w}" if @DEBUG_FONT > 0
      return w.to_f * @font_descriptor.glyph_to_pdf_scale_factor unless w.nil?
    end

    def calculate_cidfont_glyph_width(index)
      # there are two ways to calculate a cidfont_glyph_width, that are defined
      # in Section 9.7.4.3 PDF 32000-1:2008 pp 271, the differences are remarked
      # on below. because of these difference that may be contained within the
      # same array, it is a bit difficult to parse this array.
      first = -1
      last = -1
      width_spec = nil
      @cid_widths.each { |element|
        if first < 0
          first = element
        elsif element.is_a?(Array)
          width_spec = element
        elsif last < 0
          last = element
        else
          width_spec = element
        end

        if last < 0 && width_spec != nil
          # this is the form 10 [234 63 234 346 47 234] where width of index 10 is
          # 234, index 11 is 63, etc
          if index >= first && index < first + width_spec.length
            # width is spec'd in this range
            return width_spec[index - first]
          end
          first = -1
          width_spec = nil
        elsif last > 0 && width_spec != nil && width_spec > 0
          # this is the form 10 20 123 where all index between 10 and 20 have width 123
          return width_spec if index >= first && index <= last
          first = -1
          last = -1
          width_spec = nil
        end
      }
      @cid_default_width
    end

    def extract_base_info(obj)
      @subtype  = @ohash.object(obj[:Subtype])
      # A CIDFontType[0|2] will have a reference to its FontDescriptor
      # it's FontDescriptor _may_ have an embedded font program in
      # one of FontFile, FontFile2, FontFile3

      # A Type0 font is a "root font" and will have a reference to its
      # "descendant font" whose type will be a CIDFont.
      @is_cid_typ = @subtype == :CIDFontType2 || @subtype == :CIDFontType0
      @is_ttyp_typ = @subtype == :TrueType
      @basefont = @ohash.object(obj[:BaseFont])

      puts "##### Got Font // basefont: #{@basefont}   subtype: #{@subtype}" if @DEBUG_FONT > 0

      if @is_cid_typ
        # CID Fonts are not required to have a W or DW entry, if they don't exist,
        # the default cid width = 1000, see Section 9.7.4.1 PDF 32000-1:2008 pp 269
        @cid_widths         = @ohash.object(obj[:W])  || []
        @cid_default_width  = @ohash.object(obj[:DW]) || 1000
        puts "CIDFontType2 DW: #{@cid_default_width} W: #{@cid_widths.inspect}" if @DEBUG_FONT > 0
      else
        @has_to_unicode_table = false
        # TrueType has the same entries as Type1, see Section 9.6.3 PDF 32000-1:2008 pp 257
        # Type1 and Type3 are required to have a Widths, FirstChar, LastChar
        @widths   = @ohash.object(obj[:Widths]) || []
        @first_char = @ohash.object(obj[:FirstChar])
        @last_char = @ohash.object(obj[:LastChar])
        puts "Non-CID First Char: #{@first_char} Last Char: #{@last_char} " +
          "Font Widths: #{@widths.inspect}" if @DEBUG_FONT > 0
        # Encoding is required for Type3, optional for Type1
        @encoding = PDF::Reader::Encoding.new(@ohash.object(obj[:Encoding]))
        puts "Encoding:\n #{@encoding.inspect}" if @DEBUG_FONT > 0
        if obj[:ToUnicode]
          # ToUnicode is optional for Type1 and Type3
          stream = @ohash.object(obj[:ToUnicode])
          @tounicode = PDF::Reader::CMap.new(stream.unfiltered_data)
          @has_to_unicode_table = true
          puts "Unicode Table:\n #{@tounicode.inspect}" if @DEBUG_FONT > 0
        end
      end
    end

    def extract_descriptor(obj)
      if obj[:FontDescriptor]
        # create a font descriptor object if we can, in other words, unless this is
        # a CID Font
        fd = @ohash.object(obj[:FontDescriptor])
        @font_descriptor = PDF::Reader::FontDescriptor.new(@ohash, fd, @DEBUG_FONT)
      else
        @font_descriptor = nil
      end
    end

    def extract_descendants(obj)
      return unless obj[:DescendantFonts]
      # per PDF 32000-1:2008 pp. 280 :DescendentFonts is:
      # A one-element array specifying the CIDFont dictionary that is the
      # descendant of this Type 0 font.
      descendants = @ohash.object(obj[:DescendantFonts])
      @descendantfonts = descendants.map { |desc|
        PDF::Reader::Font.new(@ohash, @ohash.object(desc))
      }

      if @DEBUG_FONT > 0 && @descendantfonts
        puts "++++++++ Found Descendant Fonts"
        @descendantfonts.each {|font|
          puts font.basefont
        }
        puts "++++++++ End Descendant Fonts"
      end
    end

    def to_utf8_via_cmap(params)
      if params.class == String
        params.unpack(encoding.unpack).map { |c|
          @tounicode.decode(c) || PDF::Reader::Encoding::UNKNOWN_CHAR
        }.flatten.pack("U*")
      elsif params.class == Array
        params.collect { |param| to_utf8_via_cmap(param) }
      else
        params
      end
    end

    def to_utf8_via_encoding(params)
      if encoding.kind_of?(String)
        raise UnsupportedFeatureError, "font encoding '#{encoding}' currently unsupported"
      end

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
