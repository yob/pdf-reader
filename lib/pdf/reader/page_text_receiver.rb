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
        @current_text_group = Formatted::PageLayout::TextGroup.new(@verbosity)
        @content << @current_text_group
        @state.begin_text_object
      end

      def end_text_object # ET
        # empty the current line
        @current_line = nil
        # simplify the current text group, this may reduce the number of
        # individual lines in the group by combining lines that run into each
        # other.
        @current_text_group.simplify
        @current_text_group = nil
        @state.end_text_object
      end

      #####################################################
      # Text Positioning Operators
      #####################################################
      def move_text_position(x, y) # Td
        @state.move_text_position(x, y)
        create_new_line_at(x, y, true)
      end

      def move_text_position_and_set_leading(x, y) # TD
        @state.move_text_position_and_set_leading(x, y)
        create_new_line_at(x, y, true)
      end

      def move_to_start_of_next_line # T*
        @state.move_to_start_of_next_line
        create_new_line_at(0, 0, true)
      end

      def set_text_matrix_and_text_line_matrix(a, b, c, d, e, f) # Tm
        @state.set_text_matrix_and_text_line_matrix a, b, c, d, e, f
        create_new_line_at(e, f, true)
      end

      #####################################################
      # Text Showing Operators
      #####################################################
      # record text that is drawn on the page
      def show_text(string) # Tj (AWAY)
        if @state.current_font.nil?
          raise PDF::Reader::MalformedPDFError, "current font is invalid"
        end
        puts "string: #{@state.current_font.to_utf8(string)}"
        string.unpack("C*") do |chr|
          # paint the current glyph
          newx, newy = @state.trm_transform(0,0)

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
        exit(1)
      end

      def show_text_with_positioning(params) # TJ [(A) 120 (WA) 20 (Y)]
        internal_show_text params
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
        helper = @content.each.inject(Formatted::LayoutHelper.new(@options)) do |layout_helper, text_group|
          layout_helper.add_lines_from_text_group text_group
          layout_helper
        end
        helper.to_s
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
