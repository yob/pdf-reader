# coding: utf-8

require 'ttfunk'

module PDF
  module Preflight
    module Checks

      # check a file has no proprietary fonts. They look nice, but we can't
      # print the damn things.
      #
      class NoProprietaryFonts

        def message(ohash)
          messages = get_messages(ohash)

          if messages.size > 0
            messages.first
          else
            nil
          end
        end

        private

        def get_messages(ohash)
          array = []
          ohash.each do |key, obj|
            next unless obj.is_a?(::Hash) && obj[:Type] == :Font
            if proprietary?(ohash, obj[:FontDescriptor])
              array << "Font #{obj[:BaseFont]} is proprietary"
            end
          end
          array
        end

        def proprietary?(ohash, descriptor)
          descriptor = ohash.object(descriptor)

          return false if descriptor.nil?
          raise ArgumentError, 'expected a FontDescriptor hash' unless descriptor[:Type] == :FontDescriptor

          if descriptor.has_key?(:FontFile)
            # TODO embedded type 1 font
            false
          elsif descriptor.has_key?(:FontFile2) && ttf_proprietary?(ohash, descriptor[:FontFile2])
            true
          else
            false
          end
        end

        def ttf_proprietary?(ohash, font_file)
          font_file = ohash.object(font_file)
          ttf = TTFunk::File.new(font_file.unfiltered_data)
          #puts ttf.name.strings
          false
        end
      end
    end
  end
end
