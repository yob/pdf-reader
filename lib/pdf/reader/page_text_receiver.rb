# coding: utf-8

require 'pdf/reader/page_layout'
require 'pdf/reader/receives_text_runs'

module PDF
  class Reader

    # Builds a UTF-8 string of all the text on a single page by processing all
    # the operaters in a content stream.
    #
    class PageTextReceiver

      include ReceivesTextRuns

      def content
        PageLayout.new(@characters, @mediabox).to_s
      end

      # Start a new page
      def new_page(page)
        @characters = []
        @mediabox = page.objects.deref(page.attributes[:MediaBox])
      end

      # Process a text run
      def new_text_run(text_run)
        return if text_run.text == SPACE
        @characters << text_run
      end

    end
  end
end
