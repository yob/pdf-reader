lib/pdf/reader/page_text_receiver.rb

      # record text that is drawn on the page
      def show_text(string) # Tj
        raise PDF::Reader::MalformedPDFError, "current font is invalid" if @state.current_font.nil?
        newx, newy = @state.trm_transform(0,0)
        @content[newy] ||= ""
        @content[newy] << @state.current_font.to_utf8(string) + '|' # Kevin
      end

