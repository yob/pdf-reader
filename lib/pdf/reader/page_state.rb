# coding: utf-8
# typed: true
# frozen_string_literal: true

require 'pdf/reader/transformation_matrix'

class PDF::Reader
    # encapsulates logic for tracking graphics state as the instructions for
    # a single page are processed. Most of the public methods correspond
    # directly to PDF operators.
    class PageState

      # TODO: items int tracked in the graphics state yet:
      # clipping_path, black_generation, undercolor_removal, transfer, halftone
      #
      DEFAULT_GRAPHICS_STATE = {
        :colorspace_fill => :DeviceGray,
        :colorspace_stroke => :DeviceGray,
        :color_fill     => 1.0, # black
        :color_stroke   => 1.0, # black
        :line_width     => 1.0,
        :line_join      => 0,
        :line_cap       => 0,
        :miter_limit    => 10.0,
        :dash_pattern   => { :array => [], phase: 0 },
        :rendering_intent => :RelativeColorimetric,
        :stroke_adjustment => false,
        :blend_mode     => :Normal,
        :soft_mask      => :None,
        :alpha_constant_fill => 1.0,
        :alpha_constant_stroke => 1.0,
        :alpha_source   => false,
        :overprint_fill => false,
        :overprint_stroke => false,
        :overprint_mode => 0,
        :flatness       => 1.0,
        :smoothness     => 0, # appropriate default value?
        :char_spacing   => 0,
        :word_spacing   => 0,
        :h_scaling      => 1.0,
        :text_leading   => 0,
        :text_font      => nil,
        :text_font_size => 0,
        :text_mode      => 0,
        :text_rise      => 0,
        :text_knockout  => 0
      }

      # starting a new page
      def initialize(page)
        @page          = page
        @cache         = page.cache
        @objects       = page.objects
        @font_stack    = [build_fonts(page.fonts)]
        @xobject_stack = [page.xobjects]
        @cs_stack      = [page.color_spaces]
        @gs_stack      = [page.graphic_states]
        @stack         = [DEFAULT_GRAPHICS_STATE.dup]
        state[:ctm]  = identity_matrix

        # These are only valid when inside a `BT` block and we re-initialize them on each
        # `BT`. However, we need the instance variables set so PDFs with the text operators
        # out order don't trigger NoMethodError when these are nil
        @text_matrix      = identity_matrix
        @text_line_matrix = identity_matrix
      end

      #####################################################
      # Graphics State Operators
      #####################################################

      # Clones the current graphics state and push it onto the top of the stack.
      # Any changes that are subsequently made to the state can then by reversed
      # by calling restore_graphics_state.
      #
      def save_graphics_state
        @stack.push clone_state
      end

      # Restore the state to the previous value on the stack.
      #
      def restore_graphics_state
        @stack.pop
      end

      def set_color_rendering_intent(value)
        state[:rendering_intent] = value
      end

      def set_flatness_tolerance(value)
        state[:flatness] = value
      end

      # TODO we're not handling the following keys in graphics state dictionaries:
      # :BG, BG2, :UCR, :UCR2, :TR, :TR2, :HT, :SA, :BM, :SMask
      #
      def set_graphics_state_parameters(name)
        gs = find_graphics_state(name)
        return if gs.nil?
        puts "set_graphics_state_parameters #{name} #{gs.inspect}"
        set_line_width(gs[:LW]) if gs[:LW]
        set_line_cap_style(gs[:LC]) if gs[:LC]
        set_line_join_style(gs[:LJ]) if gs[:LJ]
        set_miter_limit(gs[:ML]) if gs[:ML]
        set_line_dash(gs[:D].first. gs[:D].last) if gs[:D]
        set_color_rendering_intent(gs[:RI]) if gs[:RI]
        if gs[:OP] && gs[:op]
          set_overprint_stroke(gs[:OP])
          set_overprint_fill(gs[:op])
        elsif gs[:OP]
          set_overprint_stroke(gs[:OP])
          set_overprint_fill(gs[:OP])
        elsif gs[:op]
          set_overprint_fill(gs[:op])
        end
        set_overprint_mode(gs[:OPM]) if gs[:OPM]
        set_text_font_and_size(gs[:Font].first, gs[:Font].last) if gs[:Font]
        set_flatness_tolerance(gs[:FL]) if gs[:FL]
        set_smoothness(gs[:SM]) if gs[:SM]
        set_alpha_constant_stroke(gs[:CA]) if gs[:CA]
        set_alpha_constant_fill(gs[:ca]) if gs[:ca]
        set_alpha_source(gs[:AIS]) if gs[:AIS]
        set_text_knockout(gs[:TK]) if gs[:TK]
      end

      def set_line_cap_style(value)
        state[:line_cap] = value.to_i
      end

      def set_line_dash(array, phase)
        state[:dash_pattern] = { :array => array, :phase => phase }
      end

      def set_line_join_style(value)
        state[:line_join] = value.to_i
      end

      def set_line_width(value)
        state[:line_width] = value
      end

      def set_miter_limit(value)
        state[:miter_limit] = value
      end

      #####################################################
      # Colour Operators
      #####################################################

      def set_cmyk_color_for_stroking(c, m, y, k)
        set_stroke_color_space(:DeviceCMYK)
        state[:color_stroke] = [c, m, y, k]
      end

      def set_cmyk_color_for_nonstroking(c, m, y, k)
        set_nonstroke_color_space(:DeviceCMYK)
        state[:color_fill] = [c, m, y, k]
      end

      def set_gray_for_stroking(value)
        set_stroke_color_space(:DeviceGray)
        state[:color_stroke] = [value]
      end

      def set_gray_for_nonstroking(value)
        set_nonstroke_color_space(:DeviceGray)
        state[:color_fill] = [value]
      end

      def set_rgb_color_for_stroking(r, g, b)
        set_stroke_color_space(:DeviceRGB)
        state[:color_stroke] = [r, g, b]
      end

      def set_rgb_color_for_nonstroking(r, g, b)
        set_nonstroke_color_space(:DeviceRGB)
        state[:color_fill] = [r, g, b]
      end

      def set_stroke_color_space(name)
        state[:colorspace_stroke] = name
      end

      def set_nonstroke_color_space(name)
        state[:colorspace_fill] = name
      end

      #####################################################
      # Matrix Operators
      #####################################################

      # update the current transformation matrix.
      #
      # If the CTM is currently undefined, just store the new values.
      #
      # If there's an existing CTM, then multiply the existing matrix
      # with the new matrix to form the updated matrix.
      #
      def concatenate_matrix(a, b, c, d, e, f)
        if state[:ctm]
          ctm = state[:ctm]
          state[:ctm] = TransformationMatrix.new(a,b,c,d,e,f).multiply!(
            ctm.a, ctm.b,
            ctm.c, ctm.d,
            ctm.e, ctm.f
          )
        else
          state[:ctm] = TransformationMatrix.new(a,b,c,d,e,f)
        end
        @text_rendering_matrix = nil # invalidate cached value
      end

      #####################################################
      # Text Object Operators
      #####################################################

      def begin_text_object
        @text_matrix      = identity_matrix
        @text_line_matrix = identity_matrix
        @font_size = nil
      end

      def end_text_object
        # don't need to do anything
      end

      #####################################################
      # Text State Operators
      #####################################################

      def set_character_spacing(char_spacing)
        state[:char_spacing] = char_spacing
      end

      def set_horizontal_text_scaling(h_scaling)
        state[:h_scaling] = h_scaling / 100.0
      end

      def set_text_font_and_size(label, size)
        state[:text_font]      = label
        state[:text_font_size] = size
      end

      def font_size
        @font_size ||= begin
                         _, zero = trm_transform(0,0)
                         _, one  = trm_transform(1,1)
                         (zero - one).abs
                       end
      end

      def set_text_leading(leading)
        state[:text_leading] = leading
      end

      def set_text_rendering_mode(mode)
        state[:text_mode] = mode
      end

      def set_text_rise(rise)
        state[:text_rise] = rise
      end

      def set_word_spacing(word_spacing)
        state[:word_spacing] = word_spacing
      end

      #####################################################
      # Text Positioning Operators
      #####################################################

      def move_text_position(x, y) # Td
        temp = TransformationMatrix.new(1, 0,
                                        0, 1,
                                        x, y)
        @text_line_matrix = temp.multiply!(
          @text_line_matrix.a, @text_line_matrix.b,
          @text_line_matrix.c, @text_line_matrix.d,
          @text_line_matrix.e, @text_line_matrix.f
        )
        @text_matrix = @text_line_matrix.dup
        @font_size = @text_rendering_matrix = nil # invalidate cached value
      end

      def move_text_position_and_set_leading(x, y) # TD
        set_text_leading(-1 * y)
        move_text_position(x, y)
      end

      def set_text_matrix_and_text_line_matrix(a, b, c, d, e, f) # Tm
        @text_matrix = TransformationMatrix.new(
          a, b,
          c, d,
          e, f
        )
        @text_line_matrix = @text_matrix.dup
        @font_size = @text_rendering_matrix = nil # invalidate cached value
      end

      def move_to_start_of_next_line # T*
        move_text_position(0, -state[:text_leading])
      end

      #####################################################
      # Text Showing Operators
      #####################################################

      def show_text_with_positioning(params) # TJ
        # TODO record position changes in state here
      end

      def move_to_next_line_and_show_text(str) # '
        move_to_start_of_next_line
      end

      def set_spacing_next_line_show_text(aw, ac, string) # "
        set_word_spacing(aw)
        set_character_spacing(ac)
        move_to_next_line_and_show_text(string)
      end

      #####################################################
      # XObjects
      #####################################################
      def invoke_xobject(label)
        save_graphics_state
        xobject = find_xobject(label)

        raise MalformedPDFError, "XObject #{label} not found" if xobject.nil?
        matrix = xobject.hash[:Matrix]
        concatenate_matrix(*matrix) if matrix

        if xobject.hash[:Subtype] == :Form
          form = PDF::Reader::FormXObject.new(@page, xobject, :cache => @cache)
          @font_stack.unshift(form.font_objects)
          @xobject_stack.unshift(form.xobjects)
          @cs_stack.unshift(form.color_spaces)
          @gs_stack.unshift(form.graphic_states)
          yield form if block_given?
          @font_stack.shift
          @xobject_stack.shift
          @gs_stack.shift
        else
          yield xobject if block_given?
        end

        restore_graphics_state
      end

      #####################################################
      # Public Visible State
      #####################################################

      # transform x and y co-ordinates from the current user space to the
      # underlying device space.
      #
      def ctm_transform(x, y)
        [
          (ctm.a * x) + (ctm.c * y) + (ctm.e),
          (ctm.b * x) + (ctm.d * y) + (ctm.f)
        ]
      end

      # transform x and y co-ordinates from the current text space to the
      # underlying device space.
      #
      # transforming (0,0) is a really common case, so optimise for it to
      # avoid unnecessary object allocations
      #
      def trm_transform(x, y)
        trm = text_rendering_matrix
        if x == 0 && y == 0
          [trm.e, trm.f]
        else
          [
            (trm.a * x) + (trm.c * y) + (trm.e),
            (trm.b * x) + (trm.d * y) + (trm.f)
          ]
        end
      end

      def current_font
        find_font(state[:text_font])
      end

      def find_font(label)
        dict = @font_stack.detect { |fonts|
          fonts.has_key?(label)
        }
        dict ? dict[label] : nil
      end

      def find_color_space(label)
        dict = @cs_stack.detect { |colorspaces|
          colorspaces.has_key?(label)
        }
        dict ? dict[label] : nil
      end

      def find_graphics_state(label)
        dict = @gs_stack.detect { |graphic_states|
          graphic_states.has_key?(label)
        }
        dict ? dict[label] : nil
      end

      def find_xobject(label)
        dict = @xobject_stack.detect { |xobjects|
          xobjects.has_key?(label)
        }
        dict ? dict[label] : nil
      end

      # when save_graphics_state is called, we need to push a new copy of the
      # current state onto the stack. That way any modifications to the state
      # will be undone once restore_graphics_state is called.
      #
      def stack_depth
        @stack.size
      end

      # This returns a deep clone of the current state, ensuring changes are
      # keep separate from earlier states.
      #
      # Marshal is used to round-trip the state through a string to easily
      # perform the deep clone. Kinda hacky, but effective.
      #
      def clone_state
        if @stack.empty?
          {}
        else
          Marshal.load Marshal.dump(@stack.last)
        end
      end

      # after each glyph is painted onto the page the text matrix must be
      # modified. There's no defined operator for this, but depending on
      # the use case some receivers may need to mutate the state with this
      # while walking a page.
      #
      # NOTE: some of the variable names in this method are obscure because
      #       they mirror variable names from the PDF spec
      #
      # NOTE: see Section 9.4.4, PDF 32000-1:2008, pp 252
      #
      # Arguments:
      #
      # w0 - the glyph width in *text space*. This generally means the width
      #      in glyph space should be divded by 1000 before being passed to
      #      this function
      # tj - any kerning that should be applied to the text matrix before the
      #      following glyph is painted. This is usually the numeric arguments
      #      in the array passed to a TJ operator
      # word_boundary - a boolean indicating if a word boundary was just
      #                 reached. Depending on the current state extra space
      #                 may need to be added
      #
      def process_glyph_displacement(w0, tj, word_boundary)
        fs = state[:text_font_size]
        tc = state[:char_spacing]
        if word_boundary
          tw = state[:word_spacing]
        else
          tw = 0
        end
        th = state[:h_scaling]
        # optimise the common path to reduce Float allocations
        if th == 1 && tj == 0 && tc == 0 && tw == 0
          tx = w0 * fs
        elsif tj != 0
          # don't apply spacing to TJ displacement
          tx = (w0 - (tj/1000.0)) * fs * th
        else
          # apply horizontal scaling to spacing values but not font size
          tx = ((w0 * fs) + tc + tw) * th
        end
        # TODO: support ty > 0
        ty = 0
        temp = TransformationMatrix.new(1, 0,
                                        0, 1,
                                        tx, ty)
        @text_matrix = temp.multiply!(
          @text_matrix.a, @text_matrix.b,
          @text_matrix.c, @text_matrix.d,
          @text_matrix.e, @text_matrix.f
        )
        @font_size = @text_rendering_matrix = nil # invalidate cached value
      end

      private

      # used for many and varied text positioning calculations. We potentially
      # need to access the results of this method many times when working with
      # text, so memoize it
      #
      def text_rendering_matrix
        @text_rendering_matrix ||= begin
          state_matrix = TransformationMatrix.new(
            state[:text_font_size] * state[:h_scaling], 0,
            0, state[:text_font_size],
            0, state[:text_rise]
          )
          state_matrix.multiply!(
            @text_matrix.a, @text_matrix.b,
            @text_matrix.c, @text_matrix.d,
            @text_matrix.e, @text_matrix.f
          )
          state_matrix.multiply!(
            ctm.a, ctm.b,
            ctm.c, ctm.d,
            ctm.e, ctm.f
          )
        end
      end

      # return the current transformation matrix
      #
      def ctm
        state[:ctm]
      end

      def state
        @stack.last
      end

      # wrap the raw PDF Font objects in handy ruby Font objects.
      #
      def build_fonts(raw_fonts)
        wrapped_fonts = raw_fonts.map { |label, font|
          [label, PDF::Reader::Font.new(@objects, @objects.deref_hash(font) || {})]
        }

        ::Hash[wrapped_fonts]
      end

      #####################################################
      # Low-level Matrix Operations
      #####################################################

      # This class uses 3x3 matrices to represent geometric transformations
      # These matrices are represented by arrays with 9 elements
      # The array [a,b,c,d,e,f,g,h,i] would represent a matrix like:
      #   a b c
      #   d e f
      #   g h i

      def identity_matrix
        TransformationMatrix.new(1, 0,
                                 0, 1,
                                 0, 0)
      end

      #####################################################
      # Graphic state updates that don't have operators, so no need for public methods
      #####################################################
      def set_overprint_stroke(value)
        state[:overprint_stroke] = value
      end

      def set_overprint_fill(value)
        state[:overprint_fill] = value
      end

      def set_overprint_mode(value)
        state[:overprint_mode] = value
      end

      def set_flatness_tolerance(value)
        state[:flatness] = value
      end

      def set_smoothness(value)
        state[:smoothness] = value
      end

      def set_alpha_constant_stroke(value)
        state[:alpha_constant_stroke] = value
      end

      def set_alpha_constant_fill(value)
        state[:alpha_constant_fill] = value
      end

      def set_alpha_source(value)
        state[:alpha_source] = value
      end

      def set_text_knockout(value)
        state[:text_knockout] = value
      end

    end
end
