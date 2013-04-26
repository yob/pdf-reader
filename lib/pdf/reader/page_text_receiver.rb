# coding: utf-8

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

      attr_reader :state, :content, :options

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

      def initialize(page_layout_opts = {})
        @page_layout_opts = page_layout_opts
        @glyph_positions = []
      end

      # starting a new page
      def page=(page)
        @state = PageState.new(page)
        @content = []
        @runs = []
        @mediabox = page.attributes[:MediaBox]
      end

      def text_runs
        if !@glyph_positions.empty?
          dump_glyph_positions
        end
        @merged_runs ||= merge_runs(@runs)
      end

      def content
        PageLayout.new(text_runs, @mediabox, @page_layout_opts).to_s
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
          else
            @state.process_glyph_displacement(0, arg, false)
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
        if @state.current_font.nil?
          raise PDF::Reader::MalformedPDFError, "current font is invalid"
        end
        @glyph_positions ||= []
        glyphs = @state.current_font.unpack(string)
        glyphs.each_with_index do |glyph_code, index|
          # paint the current glyph
          newx, newy = @state.trm_transform(0,0)
          utf8_chars = @state.current_font.to_utf8(glyph_code)

          # apply to glyph displacment for the current glyph so the next
          # glyph will appear in the correct position
          glyph_width = @state.current_font.glyph_width(glyph_code) / 1000.0
          th = 1
          scaled_glyph_width = glyph_width * @state.font_size * th
          gp = GlyphPosition.new(newx, newy, scaled_glyph_width, @state.font_size, 
            @state.current_font.basefont, utf8_chars)
          unless @glyph_positions.empty? || 
            PDF::Reader::GlyphPosition::mergable?(@glyph_positions.last, gp)
            # dump the glyph positions, assuming we have glyph positions to dump
            # and the next glyph position isn't mergable with the last glyph
            # position in the array.
            dump_glyph_positions
          end
          @glyph_positions << gp
          @state.process_glyph_displacement(glyph_width, 0, utf8_chars == SPACE)
        end
      end

      # dump the glyph positions into a TextRun
      def dump_glyph_positions
        tr = TextRun.new(@glyph_positions)
        @runs << tr
        @glyph_positions = []
      end

      # take a collection of TextRun objects and merge any that are in close
      # proximity
      def merge_runs(runs)
        runs.group_by { |run|
          run.y.to_i
        }.map { |y, runs|
          group_runs(runs.sort)
        }.flatten.sort
      end

      def group_runs(chars)
        runs = []
        while head = chars.shift
          if runs.empty?
            runs << head
          elsif runs.last.mergable?(head)
            # puts "Merging Head: #{runs.last.inspect} #{head.inspect}"
            runs[-1] = runs.last + head
          else
            runs << head
          end
        end
        runs
      end
    end
  end
end
