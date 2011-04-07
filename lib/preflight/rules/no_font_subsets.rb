# coding: utf-8

module Preflight
  module Rules

    # check a file has no font subsets. Subsets are handy and valid
    # in standards like PDFX/1a, but they make it hard to edit a
    # file
    #
    class NoFontSubsets

      def messages(ohash)
        array = []
        ohash.each do |key, obj|
          next unless obj.is_a?(::Hash) && obj[:Type] == :Font
          if subset?(obj)
            array << "Font #{obj[:BaseFont]} is a partial subset"
          end
        end
        array
      end

      private

      def subset?(font)
        font[:BaseFont] && font[:BaseFont].match(/.+\+.+/)
      end
    end
  end
end
