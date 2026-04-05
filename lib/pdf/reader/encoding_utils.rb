# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader
    class EncodingUtils

      UTF16_BOM = [254, 255] #: Array[Integer]

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

      # TODO find a PDF I can use to spec this behaviour
      #
      #: (String) -> String
      def pdfdoc_to_utf8(obj)
        obj.force_encoding(::Encoding::UTF_8)
        obj
      end

      #: (String) -> String
      def utf16_to_utf8(obj)
        obj.dup.force_encoding(::Encoding::UTF_16).encode(::Encoding::UTF_8)
      end
    end
  end
end
