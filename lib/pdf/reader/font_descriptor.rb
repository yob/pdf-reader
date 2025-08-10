# coding: utf-8
# typed: strict
# frozen_string_literal: true

require 'ttfunk'

class PDF::Reader

  # Font descriptors are outlined in Section 9.8, PDF 32000-1:2008, pp 281-288
  class FontDescriptor

    #: String
    attr_reader :font_name

    #: String?
    attr_reader :font_family

    #: Symbol
    attr_reader :font_stretch

    #: Numeric
    attr_reader :font_weight

    #: Array[Numeric]
    attr_reader :font_bounding_box

    #: Numeric
    attr_reader :cap_height

    #: Numeric
    attr_reader :ascent

    #: Numeric
    attr_reader :descent

    #: Numeric
    attr_reader :leading

    #: Numeric
    attr_reader :avg_width

    #: Numeric
    attr_reader :max_width

    #: Numeric
    attr_reader :missing_width

    #: Numeric?
    attr_reader :italic_angle

    #: Numeric?
    attr_reader :stem_v

    #: Numeric?
    attr_reader :x_height

    #: Integer
    attr_reader :font_flags

    #: (PDF::Reader::ObjectHash, Hash[untyped, untyped]) -> void
    def initialize(ohash, fd_hash)
      # TODO change these to typed derefs
      @ascent                = ohash.deref_number(fd_hash[:Ascent])    || 0 #: Numeric
      @descent               = ohash.deref_number(fd_hash[:Descent])   || 0 #: Numeric
      @missing_width         = ohash.deref_number(fd_hash[:MissingWidth]) || 0 #: Numeric
      @font_bounding_box     = ohash.deref_array_of_numbers(
        fd_hash[:FontBBox]
      ) || [0,0,0,0] #: Array[Numeric]
      @avg_width             = ohash.deref_number(fd_hash[:AvgWidth])  || 0 #: Numeric
      @cap_height            = ohash.deref_number(fd_hash[:CapHeight]) || 0 #: Numeric
      @font_flags            = ohash.deref_integer(fd_hash[:Flags])     || 0 #: Integer
      @italic_angle          = ohash.deref_number(fd_hash[:ItalicAngle]) #: Numeric?
      @font_name             = ohash.deref_name(fd_hash[:FontName]).to_s #: String
      @leading               = ohash.deref_number(fd_hash[:Leading])   || 0 #: Numeric
      @max_width             = ohash.deref_number(fd_hash[:MaxWidth])  || 0 #: Numeric
      @stem_v                = ohash.deref_number(fd_hash[:StemV]) #: Numeric?
      @x_height              = ohash.deref_number(fd_hash[:XHeight]) #: Numeric?
      @font_stretch          = ohash.deref_name(fd_hash[:FontStretch]) || :Normal #: Symbol
      @font_weight           = ohash.deref_number(fd_hash[:FontWeight])  || 400 #: Numeric
      @font_family           = ohash.deref_string(fd_hash[:FontFamily]) #: String?

      # A FontDescriptor may have an embedded font program in FontFile
      # (Type 1 Font Program), FontFile2 (TrueType font program), or
      # FontFile3 (Other font program as defined by Subtype entry)
      # Subtype entries:
      # 1) Type1C:        Type 1 Font Program in Compact Font Format
      # 2) CIDFontType0C: Type 0 Font Program in Compact Font Format
      # 3) OpenType:      OpenType Font Program
      # see Section 9.9, PDF 32000-1:2008, pp 288-292
      @font_program_stream = ohash.deref_stream(fd_hash[:FontFile2]) #: PDF::Reader::Stream?
      #TODO handle FontFile and FontFile3
      @ttf_program_stream = nil #: TTFunk::File?

      @is_ttf = @font_program_stream ? true : false #: bool
      @glyph_to_pdf_sf = nil #: Numeric?
    end

    #: (Integer) -> Numeric
    def glyph_width(char_code)
      if @is_ttf
        if ttf_program_stream.cmap.unicode.length > 0
          glyph_id = ttf_program_stream.cmap.unicode.first[char_code]
        else
          glyph_id = char_code
        end
        char_metric = ttf_program_stream.horizontal_metrics.metrics[glyph_id]
        if char_metric
          char_metric.advance_width
        else
          0
        end
      end
    end

    # PDF states that a glyph is 1000 units wide, true type doesn't enforce
    # any behavior, but uses units/em to define how wide the 'M' is (the widest letter)
    #: () -> Numeric
    def glyph_to_pdf_scale_factor
      if @is_ttf
        @glyph_to_pdf_sf ||= (1.0 / ttf_program_stream.header.units_per_em) * 1000.0
      else
        @glyph_to_pdf_sf ||= 1.0
      end
      @glyph_to_pdf_sf
    end

    private

    #: () -> TTFunk::File
    def ttf_program_stream
      raise MalformedPDFError, "No font_program_stream" unless @font_program_stream

      @ttf_program_stream ||= TTFunk::File.new(@font_program_stream.unfiltered_data)
    end
  end

end
