# coding: utf-8

require 'forwardable'

module PDF
  class Reader
    module Formatted

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
          @current_text_group = PageLayout::TextGroup.new(@verbosity)
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
        # Text State Operators
        #####################################################

        def set_character_spacing(char_spacing) # Tc
          @state.set_character_spacing(char_spacing)
        end

        def set_horizontal_text_scaling(h_scaling) # Tz
          @state.set_horizontal_text_scaling(h_scaling)
        end

        def set_text_font_and_size(label, size) #Tf
          @state.set_text_font_and_size(label, size)
        end

        def set_text_leading(leading) # TL
          @state.set_text_leading(leading)
        end

        def set_text_rendering_mode(mode) # Tr
          @state.set_text_rendering_mode(mode)
        end

        def set_text_rise(rise) # Ts
          @state.set_text_rise(rise)
        end

        def set_word_spacing(word_spacing) # Tw
          @state.set_word_spacing(word_spacing)
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
          create_new_line_at(e, f, false)
        end

        #####################################################
        # Text Showing Operators
        #####################################################
        # record text that is drawn on the page
        def show_text(string) # Tj (AWAY)
          if @state.current_font.nil?
            raise PDF::Reader::MalformedPDFError, "current font is invalid"
          end
          internal_show_text string
        end

        def show_text_with_positioning(params) # TJ [(A) 120 (WA) 20 (Y)]
          internal_show_text params
        end

        def move_to_next_line_and_show_text(str) # '
          internal_move_to_next_line_and_show_text str
        end

        def set_spacing_next_line_show_text(aw, ac, str) # "
          @state.set_word_spacing(aw)
          @state.set_character_spacing(ac)
          internal_move_to_next_line_and_show_text str
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

        def layout_page
          helper = @content.each.inject(LayoutHelper.new(@options)) do |layout_helper, text_group|
            layout_helper.add_lines_from_text_group text_group
            layout_helper
          end
          helper
        end

        private

        # create a new line of text at the given position, set this new line
        # to be the current line, and at the new line to the text group
        def create_new_line_at(x, y, should_transform)
          x_new, y_new = should_transform ? @state.trm_transform(0, 0) : [x, y]
          @current_line = PageLayout::Line.new(PageLayout::Position.new(x_new, y_new))
          @current_text_group.lines << @current_line
        end

        def internal_move_to_next_line_and_show_text(str)
          @state.move_to_start_of_next_line
          create_new_line_at(0, 0, true)
          internal_show_text(str)
        end

        # Create a new run and add to the current line
        def internal_show_text(str)
          @current_line.runs << PageLayout::Run.new(str, @state.clone_state, @state, @verbosity)
        end

      end
    end
  end
end
