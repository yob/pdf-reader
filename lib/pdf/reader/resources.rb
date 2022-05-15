# coding: utf-8
# typed: strict
# frozen_string_literal: true

module PDF
  class Reader

    # mixin for common methods in Page and FormXobjects
    #
    class Resources

      def initialize(objects, resources)
        @objects = objects
        @resources = resources
      end

      # Returns a Hash of color spaces that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def color_spaces
        @objects.deref_hash!(@resources[:ColorSpace]) || {}
      end

      # Returns a Hash of fonts that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def fonts
        @objects.deref_hash!(@resources[:Font]) || {}
      end

      # Returns a Hash of external graphic states that are available to this
      # page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def graphic_states
        @objects.deref_hash!(@resources[:ExtGState]) || {}
      end

      # Returns a Hash of patterns that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def patterns
        @objects.deref_hash!(@resources[:Pattern]) || {}
      end

      # Returns an Array of procedure sets that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def procedure_sets
        @objects.deref_array!(@resources[:ProcSet]) || []
      end

      # Returns a Hash of properties sets that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def properties
        @objects.deref_hash!(@resources[:Properties]) || {}
      end

      # Returns a Hash of shadings that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def shadings
        @objects.deref_hash!(@resources[:Shading]) || {}
      end

      # Returns a Hash of XObjects that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def xobjects
        dict = @objects.deref_hash!(@resources[:XObject]) || {}
        TypeCheck.cast_to_pdf_dict_with_stream_values!(dict)
      end

    end
  end
end
