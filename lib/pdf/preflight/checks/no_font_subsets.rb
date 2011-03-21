# coding: utf-8

module PDF
  module Preflight
    module Checks

      # check a file has no font subsets. Subsets are handy and valid
      # in standards like PDFX/1a, but they make it hard to edit a
      # file
      #
      class NoFontSubsets

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
            if subset?(obj)
              array << "Font #{obj[:BaseFont]} is a partial subset"
            end
          end
          array
        end

        def subset?(font)
          font[:BaseFont] && font[:BaseFont].match(/.+\+.+/)
        end
      end
    end
  end
end
