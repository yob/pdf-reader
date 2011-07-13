# coding: utf-8

module Preflight
  module Rules

    # check a file only uses embedded fonts
    #
    class OnlyEmbeddedFonts

      def check_page(page)
        array     = []
        resources = page.resources || {}
        fonts     = resources[:Font] || {}

        fonts.each { |key, obj|
          obj = page.objects.deref(obj)
          if !embedded?(page.objects, obj)
            array << "Font #{obj[:BaseFont]} is not embedded"
          end
        }
        array
      end

      private

      def embedded?(objects, font)
        if font.has_key?(:FontDescriptor)
          descriptor = objects.deref(font[:FontDescriptor])
          descriptor.has_key?(:FontFile) || descriptor.has_key?(:FontFile2) || descriptor.has_key?(:FontFile3)
        elsif font[:Subtype] == :Type0
          descendants = objects.deref(font[:DescendantFonts])
          descendants.all? { |f|
            f = objects.deref(f)
            embedded?(objects, f)
          }
        else
          false
        end
      end

    end
  end
end
