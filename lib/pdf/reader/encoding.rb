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
  class Encoding
    
    def self.factory(enc)
      case enc
        when nil then nil
        when "Identity-H" then PDF::Reader::Encoding::IdentityH.new
        when "MacRomanEncoding" then PDF::Reader::Encoding::MacRomanEncoding.new
        when "WinAnsiEncoding" then PDF::Reader::Encoding::WinAnsiEncoding.new
        else raise UnsupportedFeatureError, "#{enc} is not currently a supported encoding"
      end
    end

    def to_utf8(str, tounicode = nil)
      # abstract method, of sorts
      raise RuntimeError, "Called abstract method"
    end

    class IdentityH < Encoding
      def to_utf8(str, map = nil)
        raise ArgumentError, "a ToUnicode cmap is required to decode an IdentityH string" if map.nil?

        array_enc = []
        
        # iterate over string, reading it in 2 byte chunks and interpreting those
        # chunks as ints
        str.unpack("n*").each do |c|
          # convert the int to a unicode codepoint
          array_enc << map.decode(c) 
        end

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    # The default encoding for OSX <= v9
    # see: http://en.wikipedia.org/wiki/Mac_OS_Roman
    class MacRomanEncoding < Encoding
      # convert a MacRomanEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        # content of this method borrowed from REXML::Encoding.decode_cp1252
        array_latin9 = str.unpack('C*')
        array_enc = []
        array_latin9.each do |num|
          case num
            # change necesary characters to equivilant Unicode codepoints
          when 0x80; array_enc << 0x00C4
          when 0x81; array_enc << 0x00C5
          when 0x82; array_enc << 0x00C7
          when 0x83; array_enc << 0x00C9
          when 0x84; array_enc << 0x00D1
          when 0x85; array_enc << 0x00D6
          when 0x86; array_enc << 0x00DC
          when 0x87; array_enc << 0x00E1
          when 0x88; array_enc << 0x00E0
          when 0x89; array_enc << 0x00E2
          when 0x8A; array_enc << 0x00E4
          when 0x8B; array_enc << 0x00E3
          when 0x8C; array_enc << 0x00E5
          when 0x8D; array_enc << 0x00E7
          when 0x8E; array_enc << 0x00E9
          when 0x8F; array_enc << 0x00E8
          when 0x90; array_enc << 0x00EA
          when 0x91; array_enc << 0x00EB
          when 0x92; array_enc << 0x00ED
          when 0x93; array_enc << 0x00EC
          when 0x94; array_enc << 0x00EE
          when 0x95; array_enc << 0x00EF
          when 0x96; array_enc << 0x00F1
          when 0x97; array_enc << 0x00F3
          when 0x98; array_enc << 0x00F2
          when 0x99; array_enc << 0x00F4
          when 0x9A; array_enc << 0x00F6
          when 0x9B; array_enc << 0x00F5
          when 0x9C; array_enc << 0x00FA
          when 0x9D; array_enc << 0x00F9
          when 0x9E; array_enc << 0x00FB
          when 0x9F; array_enc << 0x00FC
          when 0xA0; array_enc << 0x2020
          when 0xA1; array_enc << 0x00B0
          when 0xA2; array_enc << 0x00A2
          when 0xA3; array_enc << 0x00A3
          when 0xA4; array_enc << 0x00A7
          when 0xA5; array_enc << 0x2022
          when 0xA6; array_enc << 0x00B6
          when 0xA7; array_enc << 0x00DF
          when 0xA8; array_enc << 0x00AE
          when 0xA9; array_enc << 0x00A9
          when 0xAA; array_enc << 0x2122
          when 0xAB; array_enc << 0x00B4
          when 0xAC; array_enc << 0x00A8
          when 0xAD; array_enc << 0x2260
          when 0xAE; array_enc << 0x00C6
          when 0xAF; array_enc << 0x00D8
          when 0xB0; array_enc << 0x221E
          when 0xB1; array_enc << 0x00B1
          when 0xB2; array_enc << 0x2264
          when 0xB3; array_enc << 0x2265
          when 0xB4; array_enc << 0x00A5
          when 0xB5; array_enc << 0x00B5
          when 0xB6; array_enc << 0x2202
          when 0xB7; array_enc << 0x2211
          when 0xB8; array_enc << 0x220F
          when 0xB9; array_enc << 0x03C0
          when 0xBA; array_enc << 0x222B
          when 0xBB; array_enc << 0x00AA
          when 0xBC; array_enc << 0x00BA
          when 0xBD; array_enc << 0x03A9
          when 0xBE; array_enc << 0x00E6
          when 0xBF; array_enc << 0x00F8
          when 0xC0; array_enc << 0x00BF
          when 0xC1; array_enc << 0x00A1
          when 0xC2; array_enc << 0x00AC
          when 0xC3; array_enc << 0x221A
          when 0xC4; array_enc << 0x0192
          when 0xC5; array_enc << 0x2248
          when 0xC6; array_enc << 0x2206
          when 0xC7; array_enc << 0x00AB
          when 0xC8; array_enc << 0x00BB
          when 0xC9; array_enc << 0x2026
          when 0xCA; array_enc << 0x00A0
          when 0xCB; array_enc << 0x00C0
          when 0xCC; array_enc << 0x00C3
          when 0xCD; array_enc << 0x00D5
          when 0xCE; array_enc << 0x0152
          when 0xCF; array_enc << 0x0153
          when 0xD0; array_enc << 0x2013
          when 0xD1; array_enc << 0x2014
          when 0xD2; array_enc << 0x201C
          when 0xD3; array_enc << 0x201D
          when 0xD4; array_enc << 0x2018
          when 0xD5; array_enc << 0x2019
          when 0xD6; array_enc << 0x00F7
          when 0xD7; array_enc << 0x25CA
          when 0xD8; array_enc << 0x00FF
          when 0xD9; array_enc << 0x0178
          when 0xDA; array_enc << 0x2044
          when 0xDB; array_enc << 0x20AC
          when 0xDC; array_enc << 0x2039
          when 0xDD; array_enc << 0x203A
          when 0xDE; array_enc << 0xFB01
          when 0xDF; array_enc << 0xFB02
          when 0xE0; array_enc << 0x2021
          when 0xE1; array_enc << 0x00B7
          when 0xE2; array_enc << 0x201A
          when 0xE3; array_enc << 0x201E
          when 0xE4; array_enc << 0x2030
          when 0xE5; array_enc << 0x00C2
          when 0xE6; array_enc << 0x00CA
          when 0xE7; array_enc << 0x00C1
          when 0xE8; array_enc << 0x00CB
          when 0xE9; array_enc << 0x00C8
          when 0xEA; array_enc << 0x00CD
          when 0xEB; array_enc << 0x00CE
          when 0xEC; array_enc << 0x00CF
          when 0xED; array_enc << 0x00CC
          when 0xEE; array_enc << 0x00D3
          when 0xEF; array_enc << 0x00D4
          when 0xF0; array_enc << 0xF8FF
          when 0xF1; array_enc << 0x00D2
          when 0xF2; array_enc << 0x00DA
          when 0xF3; array_enc << 0x00D8
          when 0xF4; array_enc << 0x00D9
          when 0xF5; array_enc << 0x0131
          when 0xF6; array_enc << 0x02C6
          when 0xF7; array_enc << 0x02DC
          when 0xF8; array_enc << 0x00AF
          when 0xF9; array_enc << 0x02D8
          when 0xFA; array_enc << 0x02D9
          when 0xFB; array_enc << 0x02DA
          when 0xFC; array_enc << 0x00B8
          when 0xFD; array_enc << 0x02DD
          when 0xFE; array_enc << 0x02DB
          when 0xFF; array_enc << 0x02C7
          else
            array_enc << num
          end
        end
        
        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end
    class WinAnsiEncoding < Encoding
      # convert a WinAnsiEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        # content of this method borrowed from REXML::Encoding.decode_cp1252
        # for further reading:
        # http://www.intertwingly.net/stories/2004/04/14/i18n.html
        array_latin9 = str.unpack('C*')
        array_enc = []
        array_latin9.each do |num|
          case num
            # characters that added compared to iso-8859-1
          when 0x80; array_enc << 0x20AC # 0xe2 0x82 0xac
          when 0x82; array_enc << 0x201A # 0xe2 0x82 0x9a
          when 0x83; array_enc << 0x0192 # 0xc6 0x92
          when 0x84; array_enc << 0x201E # 0xe2 0x82 0x9e
          when 0x85; array_enc << 0x2026 # 0xe2 0x80 0xa6
          when 0x86; array_enc << 0x2020 # 0xe2 0x80 0xa0
          when 0x87; array_enc << 0x2021 # 0xe2 0x80 0xa1
          when 0x88; array_enc << 0x02C6 # 0xcb 0x86
          when 0x89; array_enc << 0x2030 # 0xe2 0x80 0xb0
          when 0x8A; array_enc << 0x0160 # 0xc5 0xa0
          when 0x8B; array_enc << 0x2039 # 0xe2 0x80 0xb9
          when 0x8C; array_enc << 0x0152 # 0xc5 0x92
          when 0x8E; array_enc << 0x017D # 0xc5 0xbd
          when 0x91; array_enc << 0x2018 # 0xe2 0x80 0x98
          when 0x92; array_enc << 0x2019 # 0xe2 0x80 0x99
          when 0x93; array_enc << 0x201C # 0xe2 0x80 0x9c
          when 0x94; array_enc << 0x201D # 0xe2 0x80 0x9d
          when 0x95; array_enc << 0x2022 # 0xe2 0x80 0xa2
          when 0x96; array_enc << 0x2013 # 0xe2 0x80 0x93
          when 0x97; array_enc << 0x2014 # 0xe2 0x80 0x94
          when 0x98; array_enc << 0x02DC # 0xcb 0x9c
          when 0x99; array_enc << 0x2122 # 0xe2 0x84 0xa2
          when 0x9A; array_enc << 0x0161 # 0xc5 0xa1
          when 0x9B; array_enc << 0x203A # 0xe2 0x80 0xba
          when 0x9C; array_enc << 0x0152 # 0xc5 0x93
          when 0x9E; array_enc << 0x017E # 0xc5 0xbe
          when 0x9F; array_enc << 0x0178 # 0xc5 0xb8
          else
            array_enc << num
          end
        end
        
        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end
  end
end
