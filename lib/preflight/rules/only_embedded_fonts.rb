# coding: utf-8

module Preflight
  module Rules

    # check a file only uses embedded fonts
    #
    class OnlyEmbeddedFonts

      def check_hash(ohash)
        array = []
        ohash.each do |key, obj|
          next unless obj.is_a?(::Hash) && obj[:Type] == :Font
          if !embedded?(ohash, obj)
            array << "Font #{obj[:BaseFont]} is not embedded"
          end
        end
        array
      end

      private

      def embedded?(ohash, font)
        if font.has_key?(:FontDescriptor)
          descriptor = ohash.object(font[:FontDescriptor])
          descriptor.has_key?(:FontFile) || descriptor.has_key?(:FontFile2) || descriptor.has_key?(:FontFile3)
        elsif font[:Subtype] == :Type0
          descendants = ohash.object(font[:DescendantFonts])
          descendants.all? { |f|
            f = ohash.object(f)
            embedded?(ohash, f)
          }
        else
          false
        end
      end

    end
  end
end
