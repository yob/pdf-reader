# coding: utf-8

require 'matrix'

module PDF
  class Reader
    class PageState

      DEFAULT_GRAPHICS_STATE = {
        :ctm          => Matrix.identity(3),
        :char_spacing => 0,
        :word_spacing => 0,
        :h_scaling    => 100,
        :text_leading => 0,
        :text_font    => nil,
        :text_font_size => nil,
        :text_mode    => 0,
        :text_rise    => 0,
        :text_knockout => 0
      }

      # starting a new page
      def initialize(page)
        @page          = page
        @objects       = page.objects
        @font_stack    = [build_fonts(page.fonts)]
        @xobject_stack = [page.xobjects]
        @cs_stack      = [page.color_spaces]
        @stack         = [DEFAULT_GRAPHICS_STATE.dup]
      end

      #####################################################
      # Graphics State Operators
      #####################################################

      def save_graphics_state
        @stack.push clone_state
      end

      def restore_graphics_state
        @stack.pop
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
        transform = Matrix[
          [a, b, 0],
          [c, d, 0],
          [e, f, 1]
        ]
        if state[:ctm]
          state[:ctm] = transform * state[:ctm]
        else
          state[:ctm] = transform
        end
      end

      #####################################################
      # Text Object Operators
      #####################################################

      def begin_text_object
        @text_matrix      = Matrix.identity(3)
        @text_line_matrix = Matrix.identity(3)
      end

      def end_text_object
        @text_matrix      = Matrix.identity(3)
        @text_line_matrix = Matrix.identity(3)
      end

      #####################################################
      # Text State Operators
      #####################################################

      def set_character_spacing(char_spacing)
        state[:char_spacing] = char_spacing
      end

      def set_horizontal_text_scaling(h_scaling)
        state[:h_scaling] = h_scaling
      end

      def set_text_font_and_size(label, size)
        state[:text_font]      = label
        state[:text_font_size] = size
      end

      def font_size
        state[:text_font_size] * @text_matrix[0,0]
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
        temp_matrix = Matrix[
          [1, 0, 0],
          [0, 1, 0],
          [x, y, 1]
        ]
        @text_matrix = @text_line_matrix = temp_matrix * @text_line_matrix
      end

      def move_text_position_and_set_leading(x, y) # TD
        set_text_leading(-1 * y)
        move_text_position(x, y)
      end

      def set_text_matrix_and_text_line_matrix(a, b, c, d, e, f) # Tm
        @text_matrix = @text_line_matrix = Matrix[
          [a, b, 0],
          [c, d, 0],
          [e, f, 1]
        ]
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
          form = PDF::Reader::FormXObject.new(@page, xobject)
          @font_stack.unshift(form.font_objects)
          @xobject_stack.unshift(form.xobjects)
          yield form if block_given?
          @font_stack.shift
          @xobject_stack.shift
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
      def ctm_transform(x, y, z = 1)
        [
          (ctm[0,0] * x) + (ctm[1,0] * y) + (ctm[2,0] * z),
          (ctm[0,1] * x) + (ctm[1,1] * y) + (ctm[2,1] * z)
        ]
      end

      # transform x and y co-ordinates from the current text space to the
      # underlying device space.
      #
      def trm_transform(x, y, z = 1)
        trm = text_rendering_matrix
        [
          (trm[0,0] * x) + (trm[1,0] * y) + (trm[2,0] * z),
          (trm[0,1] * x) + (trm[1,1] * y) + (trm[2,1] * z)
        ]
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

      def find_xobject(label)
        dict = @xobject_stack.detect { |xobjects|
          xobjects.has_key?(label)
        }
        dict ? dict[label] : nil
      end

      private

      def text_rendering_matrix
        state_matrix = Matrix[
          [font_size * state[:h_scaling], 0, 0],
          [0, font_size, 0],
          [0, state[:text_rise], 1]
        ]

        state_matrix * @text_matrix * ctm
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
          [label, PDF::Reader::Font.new(@objects, @objects.deref(font))]
        }

        ::Hash[wrapped_fonts]
      end

      # when save_graphics_state is called, we need to push a new copy of the
      # current state onto the stack. That way any modifications to the state
      # will be undone once restore_graphics_state is called.
      #
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

    end
  end
end

