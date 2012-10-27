# coding: utf-8

require 'forwardable'

module PDF
  class Reader

    # Builds a UTF-8 string of all the text on a single page by processing all
    # the operaters in a content stream.
    #
    class PageTextReceiver
      extend Forwardable

      attr_reader :state, :content, :options

      ########## BEGIN FORWARDERS ##########
      # Graphics State Operators
      def_delegators :@state, :save_graphics_state, :restore_graphics_state

      # Matrix Operators
      def_delegators :@state, :concatenate_matrix

      # Text State Operators
      def_delegators :@state, :set_character_spacing, :set_horizontal_text_scaling
      def_delegators :@state, :set_text_font_and_size, :font_size
      def_delegators :@state, :set_text_leading, :set_text_rendering_mode
      def_delegators :@state, :set_text_rise, :set_word_spacing

      # Text Positioning Operators
      def_delegators :@state, :move_text_position, :move_text_position_and_set_leading
      def_delegators :@state, :set_text_matrix_and_text_line_matrix, :move_to_start_of_next_line
      ##########  END FORWARDERS  ##########

      def initialize(options = {})
        @options = options
        @verbosity = 0
      end

      # starting a new page
      def page=(page)
        @state = PageState.new(page)
        @content = []
        @characters = []
      end

      #####################################################
      # Text Object Operators
      #####################################################
      def begin_text_object # BT
        # create a new text group and add it to the content stack
        @state.begin_text_object
      end

      def end_text_object # ET
        # empty the current line
        @current_line = nil
        # simplify the current text group, this may reduce the number of
        # individual lines in the group by combining lines that run into each
        # other.
        @state.end_text_object
      end

      #####################################################
      # Text Showing Operators
      #####################################################
      # record text that is drawn on the page
      def show_text(string) # Tj (AWAY)
        internal_show_text(string)
      end

      def show_text_with_positioning(params) # TJ [(A) 120 (WA) 20 (Y)]
        params.each_slice(2).each do |string, kerning|
          internal_show_text(string, kerning || 0)
        end
      end

      def move_to_next_line_and_show_text(str) # '
        @state.move_to_start_of_next_line
        show_text(str)
      end

      def set_spacing_next_line_show_text(aw, ac, string) # "
        @state.set_word_spacing(aw)
        @state.set_character_spacing(ac)
        move_to_next_line_and_show_text(string)
      end

      #####################################################
      # XObjects
      #####################################################
      def invoke_xobject(label)
        @state.invoke_xobject(label) do |xobj|
          case xobj
          when PDF::Reader::FormXObject then
            xobj.walk(self)
          end
        end
      end

      def content
        runs = @characters.group_by { |char|
          char.y.to_i
        }.map { |y, chars|
          group_chars_into_runs(chars.sort)
        }.flatten.sort

        def_rows = @options.fetch(:number_of_rows, 100)
        def_cols = @options.fetch(:number_of_cols, 200)
        row_multiplier = @options.fetch(:row_scale, 8.0) # 800
        col_multiplier = @options.fetch(:col_scale, 3.0) # 600
        page = []
        def_value = ""
        def_cols.times { def_value << " " }
        def_rows.times { page << String.new(def_value) }
        runs.each do |run|
          x_pos = (run.x / col_multiplier).round
          y_pos = def_rows - (run.y / row_multiplier).round
          str = run.text
          if y_pos < def_rows && y_pos >= 0 && x_pos < def_cols && x_pos >= 0
            $stderr.puts "{%3d, %3d} -- %s" % [x_pos, y_pos, str.dump] if @verbosity > 2
            page[y_pos][Range.new(x_pos, x_pos + str.length - 1)] = String.new(str)
            $stderr.puts "Page[#{y_pos}] #{page[y_pos]}" if @verbosity > 2
          else
            $stderr.puts "Layout Skipping Line off of page:\n#{run}" if @verbosity > 0
          end
        end
        if @options.fetch(:strip_empty_lines, true)
          page.select! { |line| line.strip.length > 0 }
        end
        result = page.map(&:rstrip).join("\n")
        if @options.fetch(:left_strip, true)
          JustifiedLeftStrip.new(result).lstrip
        else
          result
        end
      end

      private

      def group_chars_into_runs(chars)
        runs = []
        while head = chars.shift
          if runs.empty?
            runs << head
          elsif runs.last.mergable?(head)
            runs[-1] = runs.last + head
          else
            runs << head
          end
        end
        runs
      end

      def internal_show_text(string, kerning = 0)
        if @state.current_font.nil?
          raise PDF::Reader::MalformedPDFError, "current font is invalid"
        end
        #puts "string: #{@state.current_font.to_utf8(string)}"
        glyphs = @state.current_font.split_binary_data(string)
        glyphs.each_with_index do |glyph_code, index|
          # paint the current glyph
          newx, newy = @state.trm_transform(0,0)
          utf8_chars = @state.current_font.to_utf8(glyph_code)

          # apply to glyph displacment for the current glyph so the next
          # glyph will appear in the correct position
          w0 = @state.current_font.glyph_width(glyph_code) / 1000
          #puts "#{chr.chr} w:#{w0} @ #{newx},#{newy}"
          fs = font_size # font size
          tc = @state.clone_state[:char_spacing] # character spacing
          if kerning != 0 && index == glyphs.size - 1
            tj = kerning
          else
            tj = 0
          end
          if utf8_chars == " "
            tw = @state.clone_state[:word_spacing]
          else
            tw = 0
          end
          th = 100 / 100 # scaling factor
          #puts "(((#{w0} - (#{tj}/1000)) * #{fs}) + #{tc} + #{tw}) * #{th}"
          glyph_width = ((w0 - (tj/1000.0)) * fs) * th
          tx = glyph_width + ((tc + tw) * th)
          ty = 0
          @characters << TextRun.new(newx, newy, glyph_width * th, utf8_chars)
          #puts "tx: #{tx}, ty: #{ty}"
          @state.process_glyph_displacement(tx, ty)
        end
      end

    end
  end
end
