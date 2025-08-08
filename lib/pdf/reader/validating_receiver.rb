# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader

    # Page#walk will execute the content stream of a page, calling methods on a receiver class
    # provided by the user. Each operator has a specific set of parameters it expects, and we
    # wrap the users receiver class in this one to verify the PDF uses valid parameters.
    #
    # Without these checks, users can't be confident about the number of parameters they'll receive
    # for an operator, or what the type of those parameters will be. Everyone ends up building their
    # own type safety guard clauses and it's tedious.
    #
    # Not all operators have type safety implemented yet, but we can expand the number over time.
    class ValidatingReceiver

      #: (untyped) -> void
      def initialize(wrapped)
        @wrapped = wrapped
      end

      #: (PDF::Reader::Page) -> void
      def page=(page)
        call_wrapped(:page=, page)
      end

      #####################################################
      # Graphics State Operators
      #####################################################
      #: (*untyped) -> void
      def save_graphics_state(*args)
        call_wrapped(:save_graphics_state)
      end

      #: (*untyped) -> void
      def restore_graphics_state(*args)
        call_wrapped(:restore_graphics_state)
      end

      #####################################################
      # Matrix Operators
      #####################################################

      #: (*untyped) -> void
      def concatenate_matrix(*args)
        a, b, c, d, e, f = *args
        call_wrapped(
          :concatenate_matrix,
          TypeCheck.cast_to_numeric!(a),
          TypeCheck.cast_to_numeric!(b),
          TypeCheck.cast_to_numeric!(c),
          TypeCheck.cast_to_numeric!(d),
          TypeCheck.cast_to_numeric!(e),
          TypeCheck.cast_to_numeric!(f),
        )
      end

      #####################################################
      # Text Object Operators
      #####################################################

      #: (*untyped) -> void
      def begin_text_object(*args)
        call_wrapped(:begin_text_object)
      end

      #: (*untyped) -> void
      def end_text_object(*args)
        call_wrapped(:end_text_object)
      end

      #####################################################
      # Text State Operators
      #####################################################
      #: (*untyped) -> void
      def set_character_spacing(*args)
        char_spacing, _ = *args
        call_wrapped(
          :set_character_spacing,
          TypeCheck.cast_to_numeric!(char_spacing)
        )
      end

      #: (*untyped) -> void
      def set_horizontal_text_scaling(*args)
        h_scaling, _ = *args
        call_wrapped(
          :set_horizontal_text_scaling,
          TypeCheck.cast_to_numeric!(h_scaling)
        )
      end

      #: (*untyped) -> void
      def set_text_font_and_size(*args)
        label, size, _ = *args
        call_wrapped(
          :set_text_font_and_size,
          TypeCheck.cast_to_symbol(label),
          TypeCheck.cast_to_numeric!(size)
        )
      end

      #: (*untyped) -> void
      def set_text_leading(*args)
        leading, _ = *args
        call_wrapped(
          :set_text_leading,
          TypeCheck.cast_to_numeric!(leading)
        )
      end

      #: (*untyped) -> void
      def set_text_rendering_mode(*args)
        mode, _ = *args
        call_wrapped(
          :set_text_rendering_mode,
          TypeCheck.cast_to_numeric!(mode)
        )
      end

      #: (*untyped) -> void
      def set_text_rise(*args)
        rise, _ = *args
        call_wrapped(
          :set_text_rise,
          TypeCheck.cast_to_numeric!(rise)
        )
      end

      #: (*untyped) -> void
      def set_word_spacing(*args)
        word_spacing, _ = *args
        call_wrapped(
          :set_word_spacing,
          TypeCheck.cast_to_numeric!(word_spacing)
        )
      end

      #####################################################
      # Text Positioning Operators
      #####################################################

      #: (*untyped) -> void
      def move_text_position(*args) # Td
        x, y, _ = *args
        call_wrapped(
          :move_text_position,
          TypeCheck.cast_to_numeric!(x),
          TypeCheck.cast_to_numeric!(y)
        )
      end

      #: (*untyped) -> void
      def move_text_position_and_set_leading(*args) # TD
        x, y, _ = *args
        call_wrapped(
          :move_text_position_and_set_leading,
          TypeCheck.cast_to_numeric!(x),
          TypeCheck.cast_to_numeric!(y)
        )
      end

      #: (*untyped) -> void
      def set_text_matrix_and_text_line_matrix(*args) # Tm
        a, b, c, d, e, f = *args
        call_wrapped(
          :set_text_matrix_and_text_line_matrix,
          TypeCheck.cast_to_numeric!(a),
          TypeCheck.cast_to_numeric!(b),
          TypeCheck.cast_to_numeric!(c),
          TypeCheck.cast_to_numeric!(d),
          TypeCheck.cast_to_numeric!(e),
          TypeCheck.cast_to_numeric!(f),
        )
      end

      #: (*untyped) -> void
      def move_to_start_of_next_line(*args) # T*
        call_wrapped(:move_to_start_of_next_line)
      end

      #####################################################
      # Text Showing Operators
      #####################################################
      #: (*untyped) -> void
      def show_text(*args) # Tj (AWAY)
        string, _ = *args
        call_wrapped(
          :show_text,
          TypeCheck.cast_to_string!(string)
        )
      end

      #: (*untyped) -> void
      def show_text_with_positioning(*args) # TJ [(A) 120 (WA) 20 (Y)]
        params, _ = *args
        unless params.is_a?(Array)
          raise MalformedPDFError, "TJ operator expects a single Array argument"
        end

        call_wrapped(
          :show_text_with_positioning,
          params
        )
      end

      #: (*untyped) -> void
      def move_to_next_line_and_show_text(*args) # '
        string, _ = *args
        call_wrapped(
          :move_to_next_line_and_show_text,
          TypeCheck.cast_to_string!(string)
        )
      end

      #: (*untyped) -> void
      def set_spacing_next_line_show_text(*args) # "
        aw, ac, string = *args
        call_wrapped(
          :set_spacing_next_line_show_text,
          TypeCheck.cast_to_numeric!(aw),
          TypeCheck.cast_to_numeric!(ac),
          TypeCheck.cast_to_string!(string)
        )
      end

      #####################################################
      # Form XObject Operators
      #####################################################

      #: (*untyped) -> void
      def invoke_xobject(*args)
        label, _ = *args

        call_wrapped(
          :invoke_xobject,
          TypeCheck.cast_to_symbol(label)
        )
      end

      #####################################################
      # Inline Image Operators
      #####################################################

      #: (*untyped) -> void
      def begin_inline_image(*args)
        call_wrapped(:begin_inline_image)
      end

      #: (*untyped) -> void
      def begin_inline_image_data(*args)
        # We can't use call_wrapped() here because sorbet won't allow splat args with a dynamic
        # number of elements
        @wrapped.begin_inline_image_data(*args) if @wrapped.respond_to?(:begin_inline_image_data)
      end

      #: (*untyped) -> void
      def end_inline_image(*args)
        data, _ = *args

        call_wrapped(
          :end_inline_image,
          TypeCheck.cast_to_string!(data)
        )
      end

      #####################################################
      # Final safety net for any operators that don't have type checking enabled yet
      #####################################################

      #: (untyped) -> bool
      def respond_to?(meth)
        @wrapped.respond_to?(meth)
      end

      #: (Symbol, *untyped) -> void
      def method_missing(methodname, *args)
        @wrapped.send(methodname, *args)
      end

      private

      #: (untyped, *untyped) -> void
      def call_wrapped(methodname, *args)
        @wrapped.send(methodname, *args) if @wrapped.respond_to?(methodname)
      end
    end
  end
end
