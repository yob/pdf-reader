# coding: utf-8

module PDF
  class Reader
    class PageTextReceiver
      attr_accessor :content

      def initialize(fonts)
        @fonts   = fonts
        @current = nil
        @content = ""
      end

      def set_text_font_and_size(label, size)
        @current = label
      end

      # record text that is drawn on the page
      def show_text(string, *params)
        @content << current_font.to_utf8(string)
      end

      # there's a few text callbacks, so make sure we process them all
      alias :super_show_text :show_text
      alias :move_to_next_line_and_show_text :show_text
      alias :set_spacing_next_line_show_text :show_text

      # this final text callback takes slightly different arguments
      def show_text_with_positioning(*params)
        params = params.first
        params.each { |str| show_text(str) if str.kind_of?(String)}
      end

      private

      def current_font
        @fonts[@current]
      end
    end
  end
end
