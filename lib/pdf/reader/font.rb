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

require 'pdf/reader/width_calculator'

class PDF::Reader
  # Represents a single font PDF object and provides some useful methods
  # for extracting info. Mainly used for converting text to UTF-8.
  #
  class Font
    attr_accessor :subtype, :encoding, :descendantfonts, :tounicode
    attr_reader :widths, :first_char, :last_char, :basefont, :font_descriptor,
                :cid_widths, :cid_default_width

    def initialize(ohash, obj)
      @ohash = ohash
      @tounicode = nil

      extract_base_info(obj)
      extract_type3_info(obj)
      extract_descriptor(obj)
      extract_descendants(obj)
      @width_calc = build_width_calculator

      @encoding ||= PDF::Reader::Encoding.new(:StandardEncoding)
    end

    def to_utf8(params)
      if @tounicode
        to_utf8_via_cmap(params)
      else
        to_utf8_via_encoding(params)
      end
    end

    def unpack(data)
      data.unpack(encoding.unpack)
    end

    # looks up the specified codepoint and returns a value that is in (pdf)
    # glyph space, which is 1000 glyph units = 1 text space unit
    def glyph_width(code_point)
      if code_point.is_a?(String)
        code_point = code_point.unpack(encoding.unpack).first
      end

      @cached_widths ||= {}
      @cached_widths[code_point] ||= @width_calc.glyph_width(code_point)
    end

    # In most cases glyph width is converted into text space with a simple divide by 1000.
    #
    # However, Type3 fonts provide their own FontMatrix that's used for the transformation.
    #
    def glyph_width_in_text_space(code_point)
      glyph_width_in_glyph_space = glyph_width(code_point)

      if @subtype == :Type3
        x1, _y1 = font_matrix_transform(0,0)
        x2, _y2 = font_matrix_transform(glyph_width_in_glyph_space, 0)
        (x2 - x1).abs.round(2)
      else
        glyph_width_in_glyph_space / 1000.0
      end
    end

    private

    # Only valid for Type3 fonts
    def font_matrix_transform(x, y)
      return x, y if @font_matrix.nil?

      matrix = TransformationMatrix.new(
        @font_matrix[0], @font_matrix[1],
        @font_matrix[2], @font_matrix[3],
        @font_matrix[4], @font_matrix[5],
      )

      if x == 0 && y == 0
        [matrix.e, matrix.f]
      else
        [
          (matrix.a * x) + (matrix.c * y) + (matrix.e),
          (matrix.b * x) + (matrix.d * y) + (matrix.f)
        ]
      end
    end

    def default_encoding(font_name)
      case font_name.to_s
      when "Symbol" then
        PDF::Reader::Encoding.new(:SymbolEncoding)
      when "ZapfDingbats" then
        PDF::Reader::Encoding.new(:ZapfDingbatsEncoding)
      else
        PDF::Reader::Encoding.new(:StandardEncoding)
      end
    end

    def build_width_calculator
      if @subtype == :Type0
        PDF::Reader::WidthCalculator::TypeZero.new(self)
      elsif @subtype == :Type1
        if @font_descriptor.nil?
          PDF::Reader::WidthCalculator::BuiltIn.new(self)
        else
          PDF::Reader::WidthCalculator::TypeOneOrThree .new(self)
        end
      elsif @subtype == :Type3
        PDF::Reader::WidthCalculator::TypeOneOrThree.new(self)
      elsif @subtype == :TrueType
        if @font_descriptor
          PDF::Reader::WidthCalculator::TrueType.new(self)
        else
          # A TrueType font that isn't embedded. Most readers look for a version on the
          # local system and fallback to a substitute. For now, we go straight to a substitute
          PDF::Reader::WidthCalculator::BuiltIn.new(self)
        end
      elsif @subtype == :CIDFontType0 || @subtype == :CIDFontType2
        PDF::Reader::WidthCalculator::Composite.new(self)
      else
        PDF::Reader::WidthCalculator::TypeOneOrThree.new(self)
      end
    end

    def build_encoding(obj)
      if obj[:Encoding].is_a?(Symbol)
        # one of the standard encodings, referenced by name
        # TODO pass in a standard shape, always a Hash
        PDF::Reader::Encoding.new(obj[:Encoding])
      elsif obj[:Encoding].is_a?(Hash) || obj[:Encoding].is_a?(PDF::Reader::Stream)
        PDF::Reader::Encoding.new(obj[:Encoding])
      elsif obj[:Encoding].nil?
        default_encoding(@basefont)
      else
        raise MalformedPDFError, "Unexpected type for Encoding (#{obj[:Encoding].class})"
      end
    end

    def extract_base_info(obj)
      @subtype  = @ohash.deref_name(obj[:Subtype])
      @basefont = @ohash.deref_name(obj[:BaseFont])
      @encoding = build_encoding(obj)
      @widths   = @ohash.deref_array_of_numbers(obj[:Widths]) || []
      @first_char = @ohash.deref_integer(obj[:FirstChar])
      @last_char = @ohash.deref_integer(obj[:LastChar])

      # CID Fonts are not required to have a W or DW entry, if they don't exist,
      # the default cid width = 1000, see Section 9.7.4.1 PDF 32000-1:2008 pp 269
      @cid_widths         = @ohash.deref_array(obj[:W])  || []
      @cid_default_width  = @ohash.deref_number(obj[:DW]) || 1000

      if obj[:ToUnicode]
        # ToUnicode is optional for Type1 and Type3
        stream = @ohash.deref_stream(obj[:ToUnicode])
        if stream
          @tounicode = PDF::Reader::CMap.new(stream.unfiltered_data)
        end
      end
    end

    def extract_type3_info(obj)
      if @subtype == :Type3
        @font_matrix = @ohash.deref_array_of_numbers(obj[:FontMatrix]) || [
          0.001, 0, 0, 0.001, 0, 0
        ]
      end
    end

    def extract_descriptor(obj)
      if obj[:FontDescriptor]
        # create a font descriptor object if we can, in other words, unless this is
        # a CID Font
        fd = @ohash.deref_hash(obj[:FontDescriptor])
        @font_descriptor = PDF::Reader::FontDescriptor.new(@ohash, fd)
      else
        @font_descriptor = nil
      end
    end

    def extract_descendants(obj)
      # per PDF 32000-1:2008 pp. 280 :DescendentFonts is:
      # A one-element array specifying the CIDFont dictionary that is the
      # descendant of this Type 0 font.
      if obj[:DescendantFonts]
        descendants = @ohash.deref_array(obj[:DescendantFonts])
        @descendantfonts = descendants.map { |desc|
          PDF::Reader::Font.new(@ohash, @ohash.deref_hash(desc))
        }
      else
        @descendantfonts = []
      end
    end

    def to_utf8_via_cmap(params)
      case params
      when Integer
        [
          @tounicode.decode(params) || PDF::Reader::Encoding::UNKNOWN_CHAR
        ].flatten.pack("U*")
      when String
        params.unpack(encoding.unpack).map { |c|
          @tounicode.decode(c) || PDF::Reader::Encoding::UNKNOWN_CHAR
        }.flatten.pack("U*")
      when Array
        params.collect { |param| to_utf8_via_cmap(param) }.join("")
      end
    end

    def to_utf8_via_encoding(params)
      if encoding.kind_of?(String)
        raise UnsupportedFeatureError, "font encoding '#{encoding}' currently unsupported"
      end

      case params
      when Integer
        encoding.int_to_utf8_string(params)
      when String
        encoding.to_utf8(params)
      when Array
        params.collect { |param| to_utf8_via_encoding(param) }.join("")
      end
    end

  end
end
