# coding: utf-8

module PDF
  class Reader

    # mixin for common methods in Page and FormXobjects
    #
    module ResourceMethods
      # Returns a Hash of color spaces that are available to this page
      #
      def color_spaces
        @objects.deref!(resources[:ColorSpace]) || {}
      end

      # Returns a Hash of fonts that are available to this page
      #
      def fonts
        @objects.deref!(resources[:Font]) || {}
      end

      # Returns a Hash of external graphic states that are available to this
      # page
      #
      def graphic_states
        @objects.deref!(resources[:ExtGState]) || {}
      end

      # Returns a Hash of patterns that are available to this page
      #
      def patterns
        @objects.deref!(resources[:Pattern]) || {}
      end

      # Returns an Array of procedure sets that are available to this page
      #
      def procedure_sets
        @objects.deref!(resources[:ProcSet]) || []
      end

      # Returns a Hash of properties sets that are available to this page
      #
      def properties
        @objects.deref!(resources[:Properties]) || {}
      end

      # Returns a Hash of shadings that are available to this page
      #
      def shadings
        @objects.deref!(resources[:Shading]) || {}
      end

      # Returns a Hash of XObjects that are available to this page
      #
      def xobjects
        @objects.deref!(resources[:XObject]) || {}
      end

    end
  end
end
