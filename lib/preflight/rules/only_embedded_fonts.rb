# coding: utf-8

module Preflight
  module Rules

    # check a file only uses embedded fonts
    #
    class OnlyEmbeddedFonts

      def self.rule_type
        :hash
      end

      def messages(ohash)
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
        if font[:Subtype] == :Type1 && font.has_key?(:FontDescriptor)
          true
        elsif font[:Subtype] == :TrueType && font.has_key?(:FontDescriptor)
          true
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
