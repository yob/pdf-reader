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

    attr_reader :differences

    # set the differences table for this encoding. should be an array in the following format:
    #
    #   [25, "A", 26, "B"]
    #
    # The array alternates bewteen a decimal byte number and a glyph name to map to that byte
    #
    # To save space the following array is also valid and equivilant to the previous one
    #
    #   [25, "A", "B"]
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

    # Takes the "Encoding" value of a Font dictionary and builds a PDF::Reader::Encoding object
    def self.factory(enc)
      if enc.kind_of?(Hash)
        diff = enc['Differences']
        enc = enc['Encoding'] || enc['BaseEncoding'] 
      elsif enc != nil
        enc = enc.to_s
      end

      case enc
        when nil                    then enc = PDF::Reader::Encoding::StandardEncoding.new
        when "Identity-H"           then enc = PDF::Reader::Encoding::IdentityH.new
        when "MacRomanEncoding"     then enc = PDF::Reader::Encoding::MacRomanEncoding.new
        when "MacExpertEncoding"    then enc = PDF::Reader::Encoding::MacExpertEncoding.new
        when "StandardEncoding"     then enc = PDF::Reader::Encoding::StandardEncoding.new
        when "SymbolEncoding"       then enc = PDF::Reader::Encoding::SymbolEncoding.new
        when "WinAnsiEncoding"      then enc = PDF::Reader::Encoding::WinAnsiEncoding.new
        when "ZapfDingbatsEncoding" then enc = PDF::Reader::Encoding::ZapfDingbatsEncoding.new
        else raise UnsupportedFeatureError, "#{enc} is not currently a supported encoding"
      end

      enc.differences = diff if enc && diff

      return enc
    end

    def to_utf8(str, tounicode = nil)
      # abstract method, of sorts
      raise RuntimeError, "Called abstract method"
    end

    # accepts an array of byte numbers, and replaces any that have entries in the differences table
    # with a glyph name
    def process_differences(arr)
      @differences ||= {}
      arr.collect! { |n| @differences[n].nil? ? n : @differences[n]}
    end
    protected :process_differences

    # accepts an array of unicode code points and glyphnames, and converts any glyph names to codepoints
    def process_glyphnames(arr)
      @differences ||= {}
      arr.collect! { |n| n.kind_of?(Numeric) ? n : PDF::Reader::Font.glyphnames[n]}
    end
    protected :process_glyphnames

    class IdentityH < Encoding
      def to_utf8(str, map = nil)
        
        array_enc = []

        # iterate over string, reading it in 2 byte chunks and interpreting those
        # chunks as ints
        str.unpack("n*").each do |c|
          # convert the int to a unicode codepoint if possible.
          # without a ToUnicode CMap, it's impossible to reliably convert this text
          # to unicode, so just replace each character with a little box. Big smacks
          # the the PDF producing app.
          if map
            array_enc << map.decode(c)
          else
            array_enc << 0x25FB
          end
        end
        
        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    class MacExpertEncoding < Encoding
      # convert a MacExpertEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        array_expert = str.unpack('C*')
        array_expert = self.process_differences(array_expert)
        array_enc = []
        array_expert.each do |num|
          case num
            # change necesary characters to equivilant Unicode codepoints
          when 0x21; array_enc << 0xF721
          when 0x22; array_enc << 0xF6F8 # Hungarumlautsmall
          when 0x23; array_enc << 0xF7A2
          when 0x24; array_enc << 0xF724
          when 0x25; array_enc << 0xF6E4
          when 0x26; array_enc << 0xF726
          when 0x27; array_enc << 0xF7B4
          when 0x28; array_enc << 0x207D
          when 0x29; array_enc << 0xF07E
          when 0x2A; array_enc << 0x2025
          when 0x2B; array_enc << 0x2024
          when 0x2F; array_enc << 0x2044
          when 0x30; array_enc << 0xF730
          when 0x31; array_enc << 0xF731
          when 0x32; array_enc << 0xF732
          when 0x33; array_enc << 0xF733
          when 0x34; array_enc << 0xF734
          when 0x35; array_enc << 0xF735
          when 0x36; array_enc << 0xF736
          when 0x37; array_enc << 0xF737
          when 0x38; array_enc << 0xF738
          when 0x39; array_enc << 0xF739
          when 0x3D; array_enc << 0xF6DE
          when 0x3F; array_enc << 0xF73F
          when 0x44; array_enc << 0xF7F0
          when 0x47; array_enc << 0x00BC
          when 0x48; array_enc << 0x00BD
          when 0x49; array_enc << 0x00BE
          when 0x4A; array_enc << 0x215B
          when 0x4B; array_enc << 0x215C
          when 0x4C; array_enc << 0x215D
          when 0x4D; array_enc << 0x215E
          when 0x4E; array_enc << 0x2153
          when 0x4F; array_enc << 0x2154
          when 0x56; array_enc << 0xFB00
          when 0x57; array_enc << 0xFB01
          when 0x58; array_enc << 0xFB02
          when 0x59; array_enc << 0xFB03
          when 0x5A; array_enc << 0xFB04
          when 0x5B; array_enc << 0x208D
          when 0x5D; array_enc << 0x208E
          when 0x5E; array_enc << 0xF6F6
          when 0x5F; array_enc << 0xF6E5
          when 0x60; array_enc << 0xF760
          when 0x61; array_enc << 0xF761
          when 0x62; array_enc << 0xF762
          when 0x63; array_enc << 0xF763
          when 0x64; array_enc << 0xF764
          when 0x65; array_enc << 0xF765
          when 0x66; array_enc << 0xF766
          when 0x67; array_enc << 0xF767
          when 0x68; array_enc << 0xF768
          when 0x69; array_enc << 0xF769
          when 0x6A; array_enc << 0xF76A
          when 0x6B; array_enc << 0xF76B
          when 0x6C; array_enc << 0xF76C
          when 0x6D; array_enc << 0xF76D
          when 0x6E; array_enc << 0xF76E
          when 0x6F; array_enc << 0xF76F
          when 0x70; array_enc << 0xF770
          when 0x71; array_enc << 0xF771
          when 0x72; array_enc << 0xF772
          when 0x73; array_enc << 0xF773
          when 0x74; array_enc << 0xF774
          when 0x75; array_enc << 0xF775
          when 0x76; array_enc << 0xF776
          when 0x77; array_enc << 0xF777
          when 0x78; array_enc << 0xF778
          when 0x79; array_enc << 0xF779
          when 0x7A; array_enc << 0xF77A
          when 0x7B; array_enc << 0x20A1
          when 0x7C; array_enc << 0xF6DC
          when 0x7D; array_enc << 0xF6DD
          when 0x7E; array_enc << 0xF6FE
          when 0x81; array_enc << 0xF6E9
          when 0x82; array_enc << 0xF6E0
          when 0x87; array_enc << 0xF7E1 # Acircumflexsmall
          when 0x88; array_enc << 0xF7E0
          when 0x89; array_enc << 0xF7E2 # Acutesmall
          when 0x8A; array_enc << 0xF7E4
          when 0x8B; array_enc << 0xF7E3
          when 0x8C; array_enc << 0xF7E5
          when 0x8D; array_enc << 0xF7E7
          when 0x8E; array_enc << 0xF7E9
          when 0x8F; array_enc << 0xF7E8
          when 0x90; array_enc << 0xF7E4
          when 0x91; array_enc << 0xF7EB
          when 0x92; array_enc << 0xF7ED
          when 0x93; array_enc << 0xF7EC
          when 0x94; array_enc << 0xF7EE
          when 0x95; array_enc << 0xF7EF
          when 0x96; array_enc << 0xF7F1
          when 0x97; array_enc << 0xF7F3
          when 0x98; array_enc << 0xF7F2
          when 0x99; array_enc << 0xF7F4
          when 0x9A; array_enc << 0xF7F6
          when 0x9B; array_enc << 0xF7F5
          when 0x9C; array_enc << 0xF7FA
          when 0x9D; array_enc << 0xF7F9
          when 0x9E; array_enc << 0xF7FB
          when 0x9F; array_enc << 0xF7FC
          when 0xA1; array_enc << 0x2078
          when 0xA2; array_enc << 0x2084
          when 0xA3; array_enc << 0x2083
          when 0xA4; array_enc << 0x2086
          when 0xA5; array_enc << 0x2088
          when 0xA6; array_enc << 0x2087
          when 0xA7; array_enc << 0xF6FD
          when 0xA9; array_enc << 0xF6DF
          when 0xAA; array_enc << 0x2082
          when 0xAC; array_enc << 0xF7A8
          when 0xAE; array_enc << 0xF6F5
          when 0xAF; array_enc << 0xF6F0
          when 0xB0; array_enc << 0x2085
          when 0xB2; array_enc << 0xF6E1
          when 0xB3; array_enc << 0xF6E7
          when 0xB4; array_enc << 0xF7FD
          when 0xB6; array_enc << 0xF6E3
          when 0xB9; array_enc << 0xF7FE
          when 0xBB; array_enc << 0x2089
          when 0xBC; array_enc << 0x2080
          when 0xBD; array_enc << 0xF6FF
          when 0xBE; array_enc << 0xF7E6 # AEsmall
          when 0xBF; array_enc << 0xF7F8
          when 0xC0; array_enc << 0xF7BF
          when 0xC1; array_enc << 0x2081
          when 0xC2; array_enc << 0xF6F9
          when 0xC9; array_enc << 0xF7B8
          when 0xCF; array_enc << 0xF6FA
          when 0xD0; array_enc << 0x2012
          when 0xD1; array_enc << 0xF6E6
          when 0xD6; array_enc << 0xF7A1
          when 0xD8; array_enc << 0xF7FF
          when 0xDA; array_enc << 0x00B9
          when 0xDB; array_enc << 0x00B2
          when 0xDC; array_enc << 0x00B3
          when 0xDD; array_enc << 0x2074
          when 0xDE; array_enc << 0x2075
          when 0xDF; array_enc << 0x2076
          when 0xE0; array_enc << 0x2077
          when 0xE1; array_enc << 0x2079
          when 0xE2; array_enc << 0x2070
          when 0xE4; array_enc << 0xF6EC
          when 0xE5; array_enc << 0xF6F1
          when 0xE6; array_enc << 0xF6F3
          when 0xE9; array_enc << 0xF6ED
          when 0xEA; array_enc << 0xF6F2
          when 0xEB; array_enc << 0xF6EB
          when 0xF1; array_enc << 0xF6EE
          when 0xF2; array_enc << 0xF6FB
          when 0xF3; array_enc << 0xF6F4
          when 0xF4; array_enc << 0xF7AF
          when 0xF5; array_enc << 0xF6EF
          when 0xF6; array_enc << 0x207F
          when 0xF7; array_enc << 0xF6EF
          when 0xF8; array_enc << 0xF6E2
          when 0xF9; array_enc << 0xF6E8
          when 0xFA; array_enc << 0xF6F7
          when 0xFB; array_enc << 0xF6FC
          else
            array_enc << num
          end
        end

        # convert any glyph names to unicode codepoints
        array_enc = self.process_glyphnames(array_enc)

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
        array_mac = str.unpack('C*')
        array_mac = self.process_differences(array_mac)
        array_enc = []
        array_mac.each do |num|
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

        # convert any glyph names to unicode codepoints
        array_enc = self.process_glyphnames(array_enc)

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    class StandardEncoding < Encoding
      # convert an Adobe Standard Encoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        # based on mapping described at:
        #   http://unicode.org/Public/MAPPINGS/VENDORS/ADOBE/stdenc.txt
        array_std = str.unpack('C*')
        array_std = self.process_differences(array_std)
        array_enc = []
        array_std.each do |num|
          case num
          when 0x27; array_enc << 0x2019
          when 0x60; array_enc << 0x2018
          when 0xA4; array_enc << 0x2044
          when 0xA6; array_enc << 0x0192
          when 0xA8; array_enc << 0x00A4
          when 0xA9; array_enc << 0x0027
          when 0xAA; array_enc << 0x201C
          when 0xAC; array_enc << 0x2039
          when 0xAD; array_enc << 0x203A
          when 0xAE; array_enc << 0xFB01
          when 0xAF; array_enc << 0xFB02
          when 0xB1; array_enc << 0x2013
          when 0xB2; array_enc << 0x2020
          when 0xB3; array_enc << 0x2021
          when 0xB4; array_enc << 0x00B7
          when 0xB7; array_enc << 0x2022
          when 0xB8; array_enc << 0x201A
          when 0xB9; array_enc << 0x201E
          when 0xBA; array_enc << 0x201D
          when 0xBC; array_enc << 0x2026
          when 0xBD; array_enc << 0x2030
          when 0xC1; array_enc << 0x0060
          when 0xC2; array_enc << 0x00B4
          when 0xC3; array_enc << 0x02C6
          when 0xC4; array_enc << 0x02DC
          when 0xC5; array_enc << 0x00AF
          when 0xC6; array_enc << 0x02D8
          when 0xC7; array_enc << 0x02D9
          when 0xC8; array_enc << 0x00A8
          when 0xCA; array_enc << 0x02DA
          when 0xCB; array_enc << 0x00B8
          when 0xCD; array_enc << 0x02DD
          when 0xCE; array_enc << 0x02DB
          when 0xCF; array_enc << 0x02C7
          when 0xD0; array_enc << 0x2014
          when 0xE1; array_enc << 0x00C6
          when 0xE3; array_enc << 0x00AA
          when 0xE8; array_enc << 0x0141
          when 0xE9; array_enc << 0x00D8
          when 0xEA; array_enc << 0x0152
          when 0xEB; array_enc << 0x00BA
          when 0xF1; array_enc << 0x00E6
          when 0xF5; array_enc << 0x0131
          when 0xF8; array_enc << 0x0142
          when 0xF9; array_enc << 0x00F8
          when 0xFA; array_enc << 0x0153
          when 0xFB; array_enc << 0x00DF
          else
            array_enc << num
          end
        end
        
        # convert any glyph names to unicode codepoints
        array_enc = self.process_glyphnames(array_enc)

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    class SymbolEncoding < Encoding
      # convert a SymbolEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        array_symbol = str.unpack('C*')
        array_symbol = self.process_differences(array_symbol)
        array_enc = []
        array_symbol.each do |num|
          case num
          when 0x22; array_enc << 0x2200
          when 0x24; array_enc << 0x2203
          when 0x27; array_enc << 0x220B
          when 0x2A; array_enc << 0x2217
          when 0x2D; array_enc << 0x2212
          when 0x40; array_enc << 0x2245
          when 0x41; array_enc << 0x0391
          when 0x42; array_enc << 0x0392
          when 0x43; array_enc << 0x03A7
          when 0x44; array_enc << 0x0394
          when 0x45; array_enc << 0x0395
          when 0x46; array_enc << 0x03A6
          when 0x47; array_enc << 0x0393
          when 0x48; array_enc << 0x0397
          when 0x49; array_enc << 0x0399
          when 0x4A; array_enc << 0x03D1
          when 0x4B; array_enc << 0x039A
          when 0x4C; array_enc << 0x039B
          when 0x4D; array_enc << 0x039C
          when 0x4E; array_enc << 0x039D
          when 0x4F; array_enc << 0x039F
          when 0x50; array_enc << 0x03A0
          when 0x51; array_enc << 0x0398
          when 0x52; array_enc << 0x03A1
          when 0x53; array_enc << 0x03A3
          when 0x54; array_enc << 0x03A4
          when 0x55; array_enc << 0x03A5
          when 0x56; array_enc << 0x03C2
          when 0x57; array_enc << 0x03A9
          when 0x58; array_enc << 0x039E
          when 0x59; array_enc << 0x03A8
          when 0x5A; array_enc << 0x0396
          when 0x5C; array_enc << 0x2234
          when 0x5E; array_enc << 0x22A5
          when 0x60; array_enc << 0xF8E5
          when 0x61; array_enc << 0x03B1
          when 0x62; array_enc << 0x03B2
          when 0x63; array_enc << 0x03C7
          when 0x64; array_enc << 0x03B4
          when 0x65; array_enc << 0x03B5
          when 0x66; array_enc << 0x03C6
          when 0x67; array_enc << 0x03B3
          when 0x68; array_enc << 0x03B7
          when 0x69; array_enc << 0x03B9
          when 0x6A; array_enc << 0x03D5
          when 0x6B; array_enc << 0x03BA
          when 0x6C; array_enc << 0x03BB
          when 0x6D; array_enc << 0x03BC
          when 0x6E; array_enc << 0x03BD
          when 0x6F; array_enc << 0x03BF
          when 0x70; array_enc << 0x03C0
          when 0x71; array_enc << 0x03B8
          when 0x72; array_enc << 0x03C1
          when 0x73; array_enc << 0x03C3
          when 0x74; array_enc << 0x03C4
          when 0x75; array_enc << 0x03C5
          when 0x76; array_enc << 0x03D6
          when 0x77; array_enc << 0x03C9
          when 0x78; array_enc << 0x03BE
          when 0x79; array_enc << 0x03C8
          when 0x7A; array_enc << 0x03B6
          when 0x7E; array_enc << 0x223C
          when 0xA0; array_enc << 0x20AC
          when 0xA1; array_enc << 0x03D2
          when 0xA2; array_enc << 0x2032
          when 0xA3; array_enc << 0x2264
          when 0xA4; array_enc << 0x2215
          when 0xA5; array_enc << 0x221E
          when 0xA6; array_enc << 0x0192
          when 0xA7; array_enc << 0x2663
          when 0xA8; array_enc << 0x2666
          when 0xA9; array_enc << 0x2665
          when 0xAA; array_enc << 0x2660
          when 0xAB; array_enc << 0x2194
          when 0xAC; array_enc << 0x2190
          when 0xAD; array_enc << 0x2191
          when 0xAE; array_enc << 0x2192
          when 0xAF; array_enc << 0x2193
          when 0xB2; array_enc << 0x2033
          when 0xB3; array_enc << 0x2265
          when 0xB4; array_enc << 0x00D7
          when 0xB5; array_enc << 0x221D
          when 0xB6; array_enc << 0x2202
          when 0xB7; array_enc << 0x2022
          when 0xB8; array_enc << 0x00F7
          when 0xB9; array_enc << 0x2260
          when 0xBA; array_enc << 0x2261
          when 0xBB; array_enc << 0x2248
          when 0xBC; array_enc << 0x2026
          when 0xBD; array_enc << 0xF8E6
          when 0xBE; array_enc << 0xF8E7
          when 0xBF; array_enc << 0x21B5
          when 0xC0; array_enc << 0x2135
          when 0xC1; array_enc << 0x2111
          when 0xC2; array_enc << 0x211C
          when 0xC3; array_enc << 0x2118
          when 0xC4; array_enc << 0x2297
          when 0xC5; array_enc << 0x2295
          when 0xC6; array_enc << 0x2205
          when 0xC7; array_enc << 0x2229
          when 0xC8; array_enc << 0x222A
          when 0xC9; array_enc << 0x2283
          when 0xCA; array_enc << 0x2287
          when 0xCB; array_enc << 0x2284
          when 0xCC; array_enc << 0x2282
          when 0xCD; array_enc << 0x2286
          when 0xCE; array_enc << 0x2208
          when 0xCF; array_enc << 0x2209
          when 0xD0; array_enc << 0x2220
          when 0xD1; array_enc << 0x2207
          when 0xD2; array_enc << 0xF6DA
          when 0xD3; array_enc << 0xF6D9
          when 0xD4; array_enc << 0xF6DB
          when 0xD5; array_enc << 0x220F
          when 0xD6; array_enc << 0x221A
          when 0xD7; array_enc << 0x22C5
          when 0xD8; array_enc << 0x00AC
          when 0xD9; array_enc << 0x2227
          when 0xDA; array_enc << 0x2228
          when 0xDB; array_enc << 0x21D4
          when 0xDC; array_enc << 0x21D0
          when 0xDD; array_enc << 0x21D1
          when 0xDE; array_enc << 0x21D2
          when 0xDF; array_enc << 0x21D3
          when 0xE0; array_enc << 0x25CA
          when 0xE1; array_enc << 0x2329
          when 0xE2; array_enc << 0xF8E8
          when 0xE3; array_enc << 0xF8E9
          when 0xE4; array_enc << 0xF8EA
          when 0xE5; array_enc << 0x2211
          when 0xE6; array_enc << 0xF8EB
          when 0xE7; array_enc << 0xF8EC
          when 0xE8; array_enc << 0xF8ED
          when 0xE9; array_enc << 0xF8EE
          when 0xEA; array_enc << 0xF8EF
          when 0xEB; array_enc << 0xF8F0
          when 0xEC; array_enc << 0xF8F1
          when 0xED; array_enc << 0xF8F2
          when 0xEE; array_enc << 0xF8F3
          when 0xEF; array_enc << 0xF8F4
          when 0xF1; array_enc << 0x232A
          when 0xF2; array_enc << 0x222B
          when 0xF3; array_enc << 0x2320
          when 0xF4; array_enc << 0xF8F5
          when 0xF5; array_enc << 0x2321
          when 0xF6; array_enc << 0xF8F6
          when 0xF7; array_enc << 0xF8F7
          when 0xF8; array_enc << 0xF8F8
          when 0xF9; array_enc << 0xF8F9
          when 0xFA; array_enc << 0xF8FA
          when 0xFB; array_enc << 0xF8FB
          when 0xFC; array_enc << 0xF8FC
          when 0xFD; array_enc << 0xF8FD
          when 0xFE; array_enc << 0xF8FE
          else
            array_enc << num
          end
        end

        # convert any glyph names to unicode codepoints
        array_enc = self.process_glyphnames(array_enc)

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
        array_latin9 = self.process_differences(array_latin9)
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
          when 0x93; array_enc << 0x201C
          when 0x94; array_enc << 0x201D
          when 0x95; array_enc << 0x2022
          when 0x96; array_enc << 0x2013
          when 0x97; array_enc << 0x2014
          when 0x98; array_enc << 0x02DC
          when 0x99; array_enc << 0x2122
          when 0x9A; array_enc << 0x0161
          when 0x9B; array_enc << 0x203A
          when 0x9C; array_enc << 0x0152 # 0xc5 0x93
          when 0x9E; array_enc << 0x017E # 0xc5 0xbe
          when 0x9F; array_enc << 0x0178
          else
            array_enc << num
          end
        end

        # convert any glyph names to unicode codepoints
        array_enc = self.process_glyphnames(array_enc)

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end

    class ZapfDingbatsEncoding < Encoding
      # convert a ZapfDingbatsEncoding string into UTF-8
      def to_utf8(str, tounicode = nil)
        # mapping to unicode taken from:
        #   http://unicode.org/Public/MAPPINGS/VENDORS/ADOBE/zdingbat.txt
        array_symbol = str.unpack('C*')
        array_symbol = self.process_differences(array_symbol)
        array_enc = []
        array_symbol.each do |num|
          case num
          when 0x21; array_enc << 0x2701
          when 0x22; array_enc << 0x2702
          when 0x23; array_enc << 0x2703
          when 0x24; array_enc << 0x2704
          when 0x25; array_enc << 0x260E
          when 0x26; array_enc << 0x2706
          when 0x27; array_enc << 0x2707
          when 0x28; array_enc << 0x2708
          when 0x29; array_enc << 0x2709
          when 0x2A; array_enc << 0x261B
          when 0x2B; array_enc << 0x261E
          when 0x2C; array_enc << 0x270C
          when 0x2D; array_enc << 0x270D
          when 0x2E; array_enc << 0x270E
          when 0x2F; array_enc << 0x270F
          when 0x30; array_enc << 0x2710
          when 0x31; array_enc << 0x2711
          when 0x32; array_enc << 0x2712
          when 0x33; array_enc << 0x2713
          when 0x34; array_enc << 0x2714
          when 0x35; array_enc << 0x2715
          when 0x36; array_enc << 0x2716
          when 0x37; array_enc << 0x2717
          when 0x38; array_enc << 0x2718
          when 0x39; array_enc << 0x2719
          when 0x3A; array_enc << 0x271A
          when 0x3B; array_enc << 0x271B
          when 0x3C; array_enc << 0x271C
          when 0x3D; array_enc << 0x271D
          when 0x3E; array_enc << 0x271E
          when 0x3F; array_enc << 0x271E
          when 0x40; array_enc << 0x2720
          when 0x41; array_enc << 0x2721
          when 0x42; array_enc << 0x2722
          when 0x43; array_enc << 0x2723
          when 0x44; array_enc << 0x2724
          when 0x45; array_enc << 0x2725
          when 0x46; array_enc << 0x2726
          when 0x47; array_enc << 0x2727
          when 0x48; array_enc << 0x2605
          when 0x49; array_enc << 0x2729
          when 0x4A; array_enc << 0x272A
          when 0x4B; array_enc << 0x272B
          when 0x4C; array_enc << 0x272C
          when 0x4D; array_enc << 0x272D
          when 0x4E; array_enc << 0x272E
          when 0x4F; array_enc << 0x272F
          when 0x50; array_enc << 0x2730
          when 0x51; array_enc << 0x2731
          when 0x52; array_enc << 0x2732
          when 0x53; array_enc << 0x2733
          when 0x54; array_enc << 0x2734
          when 0x55; array_enc << 0x2735
          when 0x56; array_enc << 0x2736
          when 0x57; array_enc << 0x2737
          when 0x58; array_enc << 0x2738
          when 0x59; array_enc << 0x2739
          when 0x5A; array_enc << 0x273A
          when 0x5B; array_enc << 0x273B
          when 0x5C; array_enc << 0x273C
          when 0x5D; array_enc << 0x273D
          when 0x5E; array_enc << 0x273E
          when 0x5F; array_enc << 0x273F
          when 0x60; array_enc << 0x2740
          when 0x61; array_enc << 0x2741
          when 0x62; array_enc << 0x2742
          when 0x63; array_enc << 0x2743
          when 0x64; array_enc << 0x2744
          when 0x65; array_enc << 0x2745
          when 0x66; array_enc << 0x2746
          when 0x67; array_enc << 0x2747
          when 0x68; array_enc << 0x2748
          when 0x69; array_enc << 0x2749
          when 0x6A; array_enc << 0x274A
          when 0x6B; array_enc << 0x274B
          when 0x6C; array_enc << 0x25CF
          when 0x6D; array_enc << 0x274D
          when 0x6E; array_enc << 0x25A0
          when 0x6F; array_enc << 0x274F
          when 0x70; array_enc << 0x2750
          when 0x71; array_enc << 0x2751
          when 0x72; array_enc << 0x2752
          when 0x73; array_enc << 0x2753
          when 0x74; array_enc << 0x2754
          when 0x75; array_enc << 0x2755
          when 0x76; array_enc << 0x2756
          when 0x77; array_enc << 0x2757
          when 0x78; array_enc << 0x2758
          when 0x79; array_enc << 0x2759
          when 0x7A; array_enc << 0x275A
          when 0x7B; array_enc << 0x275B
          when 0x7C; array_enc << 0x275C
          when 0x7D; array_enc << 0x275D
          when 0x7E; array_enc << 0x275E
          when 0x80; array_enc << 0xF8D7
          when 0x81; array_enc << 0xF8D8
          when 0x82; array_enc << 0xF8D9
          when 0x83; array_enc << 0xF8DA
          when 0x84; array_enc << 0xF8DB
          when 0x85; array_enc << 0xF8DC
          when 0x86; array_enc << 0xF8DD
          when 0x87; array_enc << 0xF8DE
          when 0x88; array_enc << 0xF8DF
          when 0x89; array_enc << 0xF8E0
          when 0x8A; array_enc << 0xF8E1
          when 0x8B; array_enc << 0xF8E2
          when 0x8C; array_enc << 0xF8E3
          when 0x8D; array_enc << 0xF8E4
          when 0xA1; array_enc << 0x2761
          when 0xA2; array_enc << 0x2762
          when 0xA3; array_enc << 0x2763
          when 0xA4; array_enc << 0x2764
          when 0xA5; array_enc << 0x2765
          when 0xA6; array_enc << 0x2766
          when 0xA7; array_enc << 0x2767
          when 0xA8; array_enc << 0x2663
          when 0xA9; array_enc << 0x2666
          when 0xAA; array_enc << 0x2665
          when 0xAB; array_enc << 0x2660
          when 0xAC; array_enc << 0x2460
          when 0xAD; array_enc << 0x2461
          when 0xAE; array_enc << 0x2462
          when 0xAF; array_enc << 0x2463
          when 0xB0; array_enc << 0x2464
          when 0xB1; array_enc << 0x2465
          when 0xB2; array_enc << 0x2466
          when 0xB3; array_enc << 0x2467
          when 0xB4; array_enc << 0x2468
          when 0xB5; array_enc << 0x2469
          when 0xB6; array_enc << 0x2776
          when 0xB7; array_enc << 0x2777
          when 0xB8; array_enc << 0x2778
          when 0xB9; array_enc << 0x2779
          when 0xBA; array_enc << 0x277A
          when 0xBB; array_enc << 0x277B
          when 0xBC; array_enc << 0x277C
          when 0xBD; array_enc << 0x277D
          when 0xBE; array_enc << 0x277E
          when 0xBF; array_enc << 0x277F
          when 0xC0; array_enc << 0x2780
          when 0xC1; array_enc << 0x2781
          when 0xC2; array_enc << 0x2782
          when 0xC3; array_enc << 0x2783
          when 0xC4; array_enc << 0x2784
          when 0xC5; array_enc << 0x2785
          when 0xC6; array_enc << 0x2786
          when 0xC7; array_enc << 0x2787
          when 0xC8; array_enc << 0x2788
          when 0xC9; array_enc << 0x2789
          when 0xCA; array_enc << 0x278A
          when 0xCB; array_enc << 0x278B
          when 0xCC; array_enc << 0x278C
          when 0xCD; array_enc << 0x278D
          when 0xCE; array_enc << 0x278E
          when 0xCF; array_enc << 0x278F
          when 0xD0; array_enc << 0x2790
          when 0xD1; array_enc << 0x2791
          when 0xD2; array_enc << 0x2792
          when 0xD3; array_enc << 0x2793
          when 0xD4; array_enc << 0x2794
          when 0xD5; array_enc << 0x2795
          when 0xD6; array_enc << 0x2796
          when 0xD7; array_enc << 0x2797
          when 0xD8; array_enc << 0x2798
          when 0xD9; array_enc << 0x2799
          when 0xDA; array_enc << 0x279A
          when 0xDB; array_enc << 0x279B
          when 0xDC; array_enc << 0x279C
          when 0xDD; array_enc << 0x279D
          when 0xDE; array_enc << 0x279E
          when 0xDF; array_enc << 0x279F
          when 0xE0; array_enc << 0x27A0
          when 0xE1; array_enc << 0x27A1
          when 0xE2; array_enc << 0x27A2
          when 0xE3; array_enc << 0x27A3
          when 0xE4; array_enc << 0x27A4
          when 0xE5; array_enc << 0x27A5
          when 0xE6; array_enc << 0x27A6
          when 0xE7; array_enc << 0x27A7
          when 0xE8; array_enc << 0x27A8
          when 0xE9; array_enc << 0x27A9
          when 0xEA; array_enc << 0x27AA
          when 0xEB; array_enc << 0x27AB
          when 0xEC; array_enc << 0x27AC
          when 0xED; array_enc << 0x27AD
          when 0xEE; array_enc << 0x27AE
          when 0xEF; array_enc << 0x27AF
          when 0xF1; array_enc << 0x27B1
          when 0xF2; array_enc << 0x27B2
          when 0xF3; array_enc << 0x27B3
          when 0xF4; array_enc << 0x27B4
          when 0xF5; array_enc << 0x27B5
          when 0xF6; array_enc << 0x27B6
          when 0xF7; array_enc << 0x27B7
          when 0xF8; array_enc << 0x27B8
          when 0xF9; array_enc << 0x27B9
          when 0xFA; array_enc << 0x27BA
          when 0xFB; array_enc << 0x27BB
          when 0xFC; array_enc << 0x27BC
          when 0xFD; array_enc << 0x27BD
          when 0xFE; array_enc << 0x27BE
          else
            array_enc << num
          end
        end

        # convert any glyph names to unicode codepoints
        array_enc = self.process_glyphnames(array_enc)

        # pack all our Unicode codepoints into a UTF-8 string
        ret = array_enc.pack("U*")

        # set the strings encoding correctly under ruby 1.9+
        ret.force_encoding("UTF-8") if ret.respond_to?(:force_encoding)

        return ret
      end
    end
  end
end
