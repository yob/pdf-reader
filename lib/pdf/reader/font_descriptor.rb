require 'ttfunk'

class PDF::Reader


  # Font descriptors are outlined in Section 9.8, PDF 32000-1:2008, pp 281-288
  class FontDescriptor

    attr_reader :font_name, :font_family, :font_stretch, :font_weight,
                :font_bounding_box, :cap_height, :ascent, :descent, :leading,
                :avg_width, :max_width, :missing_width, :italic_angle, :stem_v,
                :x_height, :font_flag, :is_serif, :is_fixed_width, :is_symbolic,
                :is_script, :is_italic, :is_all_caps, :is_small_caps
    @debug_font

    def initialize(ohash, fd_hash, debug_font = false)
      @debug_font = debug_font

      @ascent                = ohash.object(fd_hash[:Ascent])
      @descent               = ohash.object(fd_hash[:Descent])
      @missing_width         = ohash.object(fd_hash[:MissingWidth])
      @font_bounding_box     = ohash.object(fd_hash[:FontBBox])
      @avg_width             = ohash.object(fd_hash[:AvgWidth])
      @cap_height            = ohash.object(fd_hash[:CapHeight])
      @font_flags            = ohash.object(fd_hash[:Flags])
      @italic_angle          = ohash.object(fd_hash[:ItalicAngle])
      @font_name             = ohash.object(fd_hash[:FontName]).to_s
      @leading               = ohash.object(fd_hash[:Leading])
      @max_width             = ohash.object(fd_hash[:MaxWidth])
      @stem_v                = ohash.object(fd_hash[:StemV])
      @x_height              = ohash.object(fd_hash[:XHeight])

      # A FontDescriptor may have an embedded font program in FontFile
      # (Type 1 Font Program), FontFile2 (TrueType font program), or
      # FontFile3 (Other font program as defined by Subtype entry)
      # Subtype entries:
      # 1) Type1C:        Type 1 Font Program in Compact Font Format
      # 2) CIDFontType0C: Type 0 Font Program in Compact Font Format
      # 3) OpenType:      OpenType Font Program
      # see Section 9.9, PDF 32000-1:2008, pp 288-292
      @font_program_stream = ohash.object(fd_hash[:FontFile2]) unless fd_hash[:FontFile2] == nil
      #TODO handle FontFile and FontFile3

      if @font_name
        @font_family         =  @font_name.gsub(/^[A-Z]+\+/, '')
      else
        @font_family         ||= "%Unknown Font Family%"
      end
      @font_name             ||= "%Unknown Font Name%"
      @font_stretch          ||= "Normal"
      @font_weight           ||= 0
      @font_bounding_box     ||= [0, 0, 0,0]
      @cap_height            ||= 0
      @ascent                ||= 0
      @descent               ||= 0
      @avg_width             ||= 0
      @leading               ||= 0
      @max_width             ||= 0
      @missing_width         ||= 0
      @font_flags            ||= 0
      @is_fixed_width        = (@font_flags & 0x00001) > 0
      @is_serif              = (@font_flags & 0x00002) > 0
      @is_symbolic           = (@font_flags & 0x00004) > 0
      @is_script             = (@font_flags & 0x00008) > 0
      @is_italic             = (@font_flags & 0x00040) > 0
      @is_all_caps           = (@font_flags & 0x10000) > 0
      @is_small_caps         = (@font_flags & 0x20000) > 0

      puts self.inspect if debug_font > 0
      if @font_program_stream
        @is_ttf = true
        puts "TTF: #{self.ttf_program_stream.inspect}" if debug_font > 1
        test_ttf_program_stream if debug_font > 2
      end
    end

    def ttf_program_stream
      @ttf_program_stream ||= TTFunk::File.new(@font_program_stream.unfiltered_data)
    end

    def find_glyph_width(char_code)
      if @is_ttf
        if ttf_program_stream.cmap.unicode.length > 0
          glyph_id = ttf_program_stream.cmap.unicode.first[char_code]
        else
          glyph_id = char_code
        end
        puts "Using Char Code: #{char_code} is Glyph ID: #{glyph_id}" if @debug_font > 0
        char_metric = ttf_program_stream.horizontal_metrics.metrics[glyph_id]
        if char_metric
          puts "Char Code: #{char_code} -- Advance Width: #{char_metric.advance_width}" > 0
          return char_metric.advance_width
        end
      end
    end

    # PDF states that a glyph is 1000 units wide, true type doesn't enforce
    # any behavior, but uses units/em to define how wide the 'M' is (the widest letter)
    def glyph_to_pdf_scale_factor
      if @is_ttf
        @glyph_to_pdf_sf ||= (1.0 / ttf_program_stream.header.units_per_em) * 1000.0
      else
        @glyph_to_pdf_sf ||= 1.0
      end
      @glyph_to_pdf_sf
    end

    def test_ttf_program_stream
      file = self.ttf_program_stream
      puts "-- FONT ------------------------------------"
      puts "revision  : %08x" % file.header.font_revision
      puts "name      : #{file.name.font_name.join(', ')}"
      puts "family    : #{file.name.font_family.join(', ')}"
      puts "subfamily : #{file.name.font_subfamily.join(', ')}"
      puts "postscript: #{file.name.postscript_name}"

      puts "-- FONT METRICS ----------------------------"
      puts "units/em  : #{file.header.units_per_em}"
      puts "ascent    : #{file.ascent}"
      puts "descent   : #{file.descent}"
      puts "line gap  : #{file.line_gap}"
      puts "bbox      : (%d,%d)-(%d,%d)" % file.bbox

      puts "-- FONT TABLES ----------------------------"
      begin
        advance_list = file.horizontal_metrics.metrics.inject([]) {|advances, metric|
          advances << metric.advance_width
        }
        puts "HMTX(#{file.horizontal_metrics.metrics.count})>>>>\n#{advance_list}\n<<<<"
        file.cmap.tables.each { |table|
          puts "CMAP TABLE>>>>\nformat: #{table.format}\nplatform_id: #{table.platform_id}\nencoding_id: #{table.encoding_id}\n<<<<"
        }
        puts "UCODE MAP>>>>\n#{file.cmap.unicode.first.code_map}\n<<<<"
      rescue
        puts "problem accessing cmap"
      end
    end

    def inspect
      s = ""
      s << "-- Font Descriptor ---------------\n"
      s << " font name         : #{@font_name}\n"
      s << " font family       : #{@font_family}\n"
      s << " font stretch      : #{@font_stretch}\n"
      s << " font weight       : #{@font_weight}\n"
      s << " font bounding box : #{@font_bounding_box}\n"
      s << " cap height        : #{@cap_height}\n"
      s << " ascent            : #{@ascent}\n"
      s << " descent           : #{@descent}\n"
      s << " average width     : #{@avg_width}\n"
      s << " max. width        : #{@max_width}\n"
      s << " missing width     : #{@missing_width}\n"
      s << " leading           : #{@leading}\n"
      s << " font flags        : #{@font_flags}\n"
      s << " is fixed width    : #{@is_fixed_width}\n"
      s << " is serif          : #{@is_serif}\n"
      s << " is symbolic       : #{@is_symbolic}\n"
      s << " is script         : #{@is_script}\n"
      s << " is italic         : #{@is_italic}\n"
      s << " is all caps       : #{@is_all_caps}\n"
      s << " is small caps     : #{@is_small_caps}\n"
      s << "-- End Font Descriptor -----------\n"
    end

  end

end