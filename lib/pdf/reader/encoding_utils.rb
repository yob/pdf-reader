# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader
    # Utiliy class for some conversions to utf8 (the standard output encoding for pdf-reader).
    # This is not used for general purpose of encoding management while parsing PDFs, that lives
    # in PDF::Reader::Encoding
    class EncodingUtils

      UTF16_BOM = [254, 255] #: Array[Integer]

      # PDFDocEncoding bytes that map to Unicode codepoints differing from their
      # byte value. All other bytes map directly to their Unicode codepoint value
      # (0x00-0x17/0x20-0x7F: ASCII; 0xA1-0xFF: Latin-1, which PDFDocEncoding
      # matches exactly).
      PDFDOC_CODEPOINTS = {
        0x18 => 0x02D8, # BREVE
        0x19 => 0x02C7, # CARON
        0x1A => 0x02C6, # MODIFIER LETTER CIRCUMFLEX ACCENT
        0x1B => 0x02D9, # DOT ABOVE
        0x1C => 0x02DD, # DOUBLE ACUTE ACCENT
        0x1D => 0x02DB, # OGONEK
        0x1E => 0x02DA, # RING ABOVE
        0x1F => 0x02DC, # SMALL TILDE
        0x80 => 0x2022, # BULLET
        0x81 => 0x2020, # DAGGER
        0x82 => 0x2021, # DOUBLE DAGGER
        0x83 => 0x2026, # HORIZONTAL ELLIPSIS
        0x84 => 0x2014, # EM DASH
        0x85 => 0x2013, # EN DASH
        0x86 => 0x0192, # LATIN SMALL LETTER F WITH HOOK
        0x87 => 0x2044, # FRACTION SLASH
        0x88 => 0x2039, # SINGLE LEFT-POINTING ANGLE QUOTATION MARK
        0x89 => 0x203A, # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
        0x8A => 0x2212, # MINUS SIGN
        0x8B => 0x2030, # PER MILLE SIGN
        0x8C => 0x201E, # DOUBLE LOW-9 QUOTATION MARK
        0x8D => 0x201C, # LEFT DOUBLE QUOTATION MARK
        0x8E => 0x201D, # RIGHT DOUBLE QUOTATION MARK
        0x8F => 0x2018, # LEFT SINGLE QUOTATION MARK
        0x90 => 0x2019, # RIGHT SINGLE QUOTATION MARK
        0x91 => 0x201A, # SINGLE LOW-9 QUOTATION MARK
        0x92 => 0x2122, # TRADE MARK SIGN
        0x93 => 0xFB01, # LATIN SMALL LIGATURE FI
        0x94 => 0xFB02, # LATIN SMALL LIGATURE FL
        0x95 => 0x0141, # LATIN CAPITAL LETTER L WITH STROKE
        0x96 => 0x0152, # LATIN CAPITAL LIGATURE OE
        0x97 => 0x0160, # LATIN CAPITAL LETTER S WITH CARON
        0x98 => 0x0178, # LATIN CAPITAL LETTER Y WITH DIAERESIS
        0x99 => 0x017D, # LATIN CAPITAL LETTER Z WITH CARON
        0x9A => 0x0131, # LATIN SMALL LETTER DOTLESS I
        0x9B => 0x0142, # LATIN SMALL LETTER L WITH STROKE
        0x9C => 0x0153, # LATIN SMALL LIGATURE OE
        0x9D => 0x0161, # LATIN SMALL LETTER S WITH CARON
        0x9E => 0x017E, # LATIN SMALL LETTER Z WITH CARON
        0xA0 => 0x20AC, # EURO SIGN
      }.freeze #: Hash[Integer, Integer]

     #: (untyped) -> untyped
      def self.obj_to_utf8(obj)
        new.obj_to_utf8(obj)
      end

      #: (String) -> String
      def self.string_to_utf8(str)
        new.string_to_utf8(str)
      end

      # Recursively convert Hashes, Arrays, and Strings to UTF-8
      #
      #: (untyped) -> untyped
      def obj_to_utf8(obj)
        case obj
        when ::Hash then
          {}.tap { |new_hash|
            obj.each do |key, value|
              new_hash[key] = obj_to_utf8(value)
            end
          }
        when Array then
          obj.map { |item| obj_to_utf8(item) }
        when String then
          string_to_utf8(obj)
        else
          obj
        end
      end

      # Convert a String to UTF-8
      #
      #: (String) -> String
      def string_to_utf8(str)
        if has_utf16_bom?(str)
          utf16_to_utf8(str)
        else
          pdfdoc_to_utf8(str)
        end
      end

      private

      #: (String) -> bool
      def has_utf16_bom?(str)
        first_bytes = str[0,2]

        return false if first_bytes.nil?

        first_bytes.unpack("C*") == UTF16_BOM
      end

      #: (String) -> String
      def pdfdoc_to_utf8(str)
        str.bytes.map { |b| PDFDOC_CODEPOINTS[b] || b }.pack("U*")
      end

      #: (String) -> String
      def utf16_to_utf8(obj)
        obj.dup.force_encoding(
          ::Encoding::UTF_16
        ).encode(
          ::Encoding::UTF_8, invalid: :replace, replace: "\uFFFD"
        )
      end
    end
  end
end
