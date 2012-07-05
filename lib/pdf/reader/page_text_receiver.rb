# coding: utf-8

require 'matrix'
require 'forwardable'

module PDF
  class Reader
    class PageTextReceiver
      extend Forwardable

      # Graphics State Operators
      def_delegators :@state, :save_graphics_state, :restore_graphics_state

      # Matrix Operators
      def_delegators :@state, :concatenate_matrix

      # Text Object Operators
      def_delegators :@state, :begin_text_object, :end_text_object

      # Text State Operators
      def_delegators :@state, :set_character_spacing, :set_horizontal_text_scaling
      def_delegators :@state, :set_text_font_and_size, :font_size
      def_delegators :@state, :set_text_leading, :set_text_rendering_mode
      def_delegators :@state, :set_text_rise, :set_word_spacing

      # Text Positioning Operators
      def_delegators :@state, :move_text_position, :move_text_position_and_set_leading
      def_delegators :@state, :set_text_matrix_and_text_line_matrix, :move_to_start_of_next_line

      # starting a new page
      def page=(page)
        @state = PageState.new(page)
        @content = {}
      end

      def content
        keys = @content.keys.sort.reverse
        keys.map { |key|
          @content[key]
        }.join("\n")
      end

      #####################################################
      # Text Showing Operators
      #####################################################

      # record text that is drawn on the page
      def show_text(string) # Tj
        raise PDF::Reader::MalformedPDFError, "current font is invalid" if @state.current_font.nil?
        newx, newy = @state.trm_transform(0,0)
        @content[newy] ||= ""
        @content[newy] << @state.current_font.to_utf8(string)
      end

      def show_text_with_positioning(params) # TJ
        params.each { |arg|
          case arg
          when String
            show_text(arg)
          when Fixnum, Float
            show_text(" ") if arg > 1000
          end
        }
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

    end
  end
end
