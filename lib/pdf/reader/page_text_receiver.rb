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
      ##########  END FORWARDERS  ##########

      def initialize(options = {})
        @options = options
        @verbosity = 0
      end

      # starting a new page
      def page=(page)
        @state = PageState.new(page)
        @content = []
      end

      #####################################################
      # Text Object Operators
      #####################################################
      def begin_text_object # BT
        # create a new text group and add it to the content stack
        @characters = []
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
      # Text Positioning Operators
      #####################################################
      def move_text_position(x, y) # Td
        @state.move_text_position(x, y)
      end

      def move_text_position_and_set_leading(x, y) # TD
        @state.move_text_position_and_set_leading(x, y)
      end

      def move_to_start_of_next_line # T*
        @state.move_to_start_of_next_line
      end

      def set_text_matrix_and_text_line_matrix(a, b, c, d, e, f) # Tm
        @state.set_text_matrix_and_text_line_matrix a, b, c, d, e, f
      end

      #####################################################
      # Text Showing Operators
      #####################################################
      # record text that is drawn on the page
      def show_text(string) # Tj (AWAY)
        if @state.current_font.nil?
          raise PDF::Reader::MalformedPDFError, "current font is invalid"
        end
        #puts "string: #{@state.current_font.to_utf8(string)}"
        string.unpack("C*") do |chr|
          # paint the current glyph
          newx, newy = @state.trm_transform(0,0)
          @characters << Character.new(newx, newy, chr.chr)

          # apply to glyph displacment for the current glyph so the next
          # glyph will appear in the correct position
          w0 = @state.current_font.glyph_width(chr) / 1000
          puts "#{chr.chr} w:#{w0} @ #{newx},#{newy}"
          tj = 0         # kerning
          fs = font_size # font size
          tc = @state.clone_state[:char_spacing] # character spacing
          if chr == 32
            tw = @state.clone_state[:word_spacing]
          else
            tw = 0
          end
          th = 100 / 100 # scaling factor
          #puts "(((#{w0} - (#{tj}/1000)) * #{fs}) + #{tc} + #{tw}) * #{th}"
          tx = (((w0 - (tj/1000)) * fs) + tc + tw) * th
          ty = 0
          #puts "tx: #{tx}, ty: #{ty}"
          @state.move_text_position(tx, ty)
        end
      end

      class Character < Struct.new(:x, :y, :text)
        include Comparable

        def <=>(other)
          [x,y] <=> [other.x, other.y]
        end

        def to_s
          text
        end

        def inspect
          "#{text} @#{x},#{y}"
        end
      end

      def show_text_with_positioning(params) # TJ [(A) 120 (WA) 20 (Y)]
        raise "implement this!"
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
        def_rows = @options.fetch(:number_of_rows, 100)
        def_cols = @options.fetch(:number_of_cols, 200)
        row_multiplier = @options.fetch(:row_scale, 8.0) # 800
        col_multiplier = @options.fetch(:col_scale, 3.0) # 600
        page = []
        def_value = ""
        def_cols.times { def_value << " " }
        def_rows.times { page << String.new(def_value) }
        @characters.each do |char|
          x_pos = (char.x / col_multiplier).round
          y_pos = def_rows - (char.y / row_multiplier).round
          if y_pos < def_rows && y_pos >= 0 && x_pos < def_cols && x_pos >= 0
            page[y_pos][Range.new(x_pos, x_pos + char.text.length - 1)] = String.new(char.text)
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

      # create a new line of text at the given position, set this new line
      # to be the current line, and at the new line to the text group
      def create_new_line_at(x, y, should_transform)
        x_new, y_new = should_transform ? @state.trm_transform(0, 0) : [x, y]
        @current_line = Formatted::PageLayout::Line.new(Formatted::PageLayout::Position.new(x_new, y_new))
        @current_text_group.lines << @current_line
      end

      def internal_move_to_next_line_and_show_text(str)
        @state.move_to_start_of_next_line
        create_new_line_at(0, 0, true)
        internal_show_text(str)
      end

      # Create a new run and add to the current line
      def internal_show_text(str)
        @current_line.runs << Formatted::PageLayout::Run.new(str, @state.clone_state, @state, @verbosity)
      end

    end
  end
end
