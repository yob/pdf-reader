# coding: utf-8
# typed: true
# frozen_string_literal: true

require 'forwardable'
require 'pdf/reader/page_layout'

module PDF
  class Reader

    # Builds a UTF-8 string of all the text on a single page by processing all
    # the operaters in a content stream.
    #
    class PageTextReceiver
      extend Forwardable

      SPACE = " "

      attr_reader :state, :options

      ########## BEGIN FORWARDERS ##########
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
      ##########  END FORWARDERS  ##########

      # starting a new page
      def page=(page)
        @state = PageState.new(page)
        @page = page
        @content = []
        @characters = []
      end

      def runs(opts = {})
        runs = @characters

        if rect = opts.fetch(:rect, @page.rectangles[:CropBox])
          runs = BoundingRectangleRunsFilter.runs_within_rect(runs, rect)
        end

        if opts.fetch(:skip_zero_width, true)
          runs = ZeroWidthRunsFilter.exclude_zero_width_runs(runs)
        end

        if opts.fetch(:skip_overlapping, true)
          runs = OverlappingRunsFilter.exclude_redundant_runs(runs)
        end

        runs = NoTextFilter.exclude_empty_strings(runs)

        if opts.fetch(:merge, true)
          runs = merge_runs(runs)
        end

        runs
      end

      # deprecated
      def content
        mediabox = @page.rectangles[:MediaBox]
        PageLayout.new(runs, mediabox).to_s
      end

      #####################################################
      # Text Showing Operators
      #####################################################
      # record text that is drawn on the page
      def show_text(string) # Tj (AWAY)
        internal_show_text(string)
      end

      def show_text_with_positioning(params) # TJ [(A) 120 (WA) 20 (Y)]
        params.each do |arg|
          if arg.is_a?(String)
            internal_show_text(arg)
          elsif arg.is_a?(Numeric)
            @state.process_glyph_displacement(0, arg, false)
          else
            # skip it
          end
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

      private

      def internal_show_text(string)
        PDF::Reader::Error.validate_type_as_malformed(string, "string", String)
        if @state.current_font.nil?
          raise PDF::Reader::MalformedPDFError, "current font is invalid"
        end
        glyphs = @state.current_font.unpack(string)
        glyphs.each_with_index do |glyph_code, index|
          # paint the current glyph
          newx, newy = @state.trm_transform(0,0)
          newx, newy = apply_rotation(newx, newy)

          utf8_chars = @state.current_font.to_utf8(glyph_code)

          # apply to glyph displacment for the current glyph so the next
          # glyph will appear in the correct position
          glyph_width = @state.current_font.glyph_width_in_text_space(glyph_code)
          th = 1
          scaled_glyph_width = glyph_width * @state.font_size * th
          unless utf8_chars == SPACE
            @characters << TextRun.new(newx, newy, scaled_glyph_width, @state.font_size, utf8_chars)
          end
          @state.process_glyph_displacement(glyph_width, 0, utf8_chars == SPACE)
        end
      end

      def apply_rotation(x, y)
        if @page.rotate == 90
          tmp = x
          x = y
          y = tmp * -1
        elsif @page.rotate == 180
          y *= -1
          x *= -1
        elsif @page.rotate == 270
          tmp = y
          y = x
          x = tmp * -1
        end
        return x, y
      end

      # take a collection of TextRun objects and merge any that are in close
      # proximity
      def merge_runs(runs)
        runs.group_by { |char|
          char.y.to_i
        }.map { |y, chars|
          group_chars_into_runs(chars.sort)
        }.flatten.sort
      end

      def group_chars_into_runs(chars)
        chars.each_with_object([]) do |char, runs|
          if runs.empty?
            runs << char
          elsif runs.last.mergable?(char)
            runs[-1] = runs.last + char
          else
            runs << char
          end
        end
      end

    end
  end
end
