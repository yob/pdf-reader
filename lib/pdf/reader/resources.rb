# coding: utf-8
# typed: true
# frozen_string_literal: true

# Setting this file to "typed: true" is difficult because it's a mixin that assumes some things
# are aavailable from the class, like @objects and resources. Sorbet doesn't know about them.

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
        (@objects.deref!(@resources[:ColorSpace]) || {}).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "ColorSpace dictionary", Hash)
        }
      end

      # Returns a Hash of fonts that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def fonts
        (@objects.deref!(@resources[:Font]) || {}).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "Fonts dictionary", Hash)
        }
      end

      # Returns a Hash of external graphic states that are available to this
      # page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def graphic_states
        (@objects.deref!(@resources[:ExtGState]) || {}).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "ExtGState dictionary", Hash)
        }
      end

      # Returns a Hash of patterns that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def patterns
        (@objects.deref!(@resources[:Pattern]) || {}).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "Patterns dictionary", Hash)
        }
      end

      # Returns an Array of procedure sets that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def procedure_sets
        (@objects.deref!(@resources[:ProcSet]) || []).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "ProcSet array", Array)
        }
      end

      # Returns a Hash of properties sets that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def properties
        (@objects.deref!(@resources[:Properties]) || {}).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "Properties dictionary", Hash)
        }
      end

      # Returns a Hash of shadings that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def shadings
        (@objects.deref!(@resources[:Shading]) || {}).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "Shading dictionary", Hash)
        }
      end

      # Returns a Hash of XObjects that are available to this page
      #
      # NOTE: this method de-serialise objects from the underlying PDF
      #       with no caching. You will want to cache the results instead
      #       of calling it over and over.
      #
      def xobjects
        (@objects.deref!(@resources[:XObject]) || {}).tap { |obj|
          PDF::Reader::Error.validate_type_as_malformed(obj, "XObject dictionary", Hash)
        }
      end

    end
  end
end
