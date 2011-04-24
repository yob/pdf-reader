# coding: utf-8

require 'yaml'
require 'matrix'

module Preflight
  module Rules

    # For high quality prints, you generally want raster images to be
    # AT LEAST 300 points-per-inch (ppi). 600 is better, 1200 better again.
    #
    class MinPpi
      include Preflight::Measurements

      DEFAULT_GRAPHICS_STATE = {
        :ctm => Matrix.identity(3)
      }

      attr_reader :messages

      def initialize(min_ppi)
        @min_ppi = min_ppi.to_i
        @messages = []
        @page_num = 0
      end

      def save_graphics_state
        @stack.push clone_state
      end

      def restore_graphics_state
        @stack.pop
      end

      def state
        @stack.last
      end

      # store sample width and height for each image on the current page
      #
      def resource_xobject(label, stream)
        return unless stream.hash[:Subtype] == :Image

        @images[label] = [
          stream.hash[:Width],
          stream.hash[:Height]
        ]
      end

      # update the current transform matrix.
      #
      # If the CTM is currently undefined, just store the new values.
      #
      # If there's an existing CTM, then multiple the existing matrix
      # with the new matrix to form the updated matrix.
      #
      def concatenate_matrix(*args)
        transform = Matrix[
          [args[0], args[1], 0],
          [args[2], args[3], 0],
          [args[4], args[5], 1]
        ]
        if state[:ctm]
          state[:ctm] = transform * state[:ctm]
        else
          state[:ctm] = transform
        end
      end

      # As each image is drawn on the canvas, determine the amount of device
      # space it's being crammed into and therefore the PPI.
      #
      def invoke_xobject(label)
        return unless @images[label]

        sample_w, sample_h = *@images[label]
        device_w = pt2in(state[:ctm][0,0]).abs
        device_h = pt2in(state[:ctm][1,1]).abs

        horizontal_ppi = (sample_w / device_w).round(3)
        vertical_ppi   = (sample_h / device_h).round(3)

        if horizontal_ppi < @min_ppi || vertical_ppi < @min_ppi
          @messages << "Image with low PPI/DPI on page #{@page_num} (h:#{horizontal_ppi} v:#{vertical_ppi})"
        end
      end

      # start fresh on every page
      #
      def begin_page(hash = {})
        @images = {}
        @page_num += 1
        @stack = [DEFAULT_GRAPHICS_STATE]
      end

      private

      # when save_graphics_state is called, we need to push a new copy of the
      # current state onto the stack. That way any modifications to the state
      # will be undone once restore_graphics_state is called.
      #
      # This returns a deep clone of the current state, ensuring changes are
      # keep separate from earlier states.
      #
      # YAML is used to round-trip the state through a string to easily perform
      # the deep clone. Kinda hacky, but effective.
      #
      def clone_state
        if @stack.empty?
          {}
        else
          yaml_state = YAML.dump(@stack.last)
          YAML.load(yaml_state)
        end
      end
    end
  end
end
