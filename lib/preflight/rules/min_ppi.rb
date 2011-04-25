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

      # update the current transformation matrix.
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
        device_w = pt2in(image_width)
        device_h = pt2in(image_height)

        horizontal_ppi = (sample_w / device_w)
        vertical_ppi   = (sample_h / device_h)

        if horizontal_ppi.infinite?
          @messages << "Divide by zero in horizontal ppi on page #{@page_num}"
        elsif vertical_ppi.infinite?
          @messages << "Divide by zero in vertical ppi on page #{@page_num}"
        elsif horizontal_ppi < @min_ppi || vertical_ppi < @min_ppi
          @messages << "Image with low PPI/DPI on page #{@page_num} (h:#{horizontal_ppi.round(3)} v:#{vertical_ppi.round(3)})"
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

      # return the current transformation matrix
      #
      def ctm
        state[:ctm]
      end

      # transform x and y co-ordinates from the current user space to the
      # underlying device space.
      #
      def transform(x, y, z = 1)
        newx = (ctm[0,0] * x) + (ctm[1,0] * y) + (ctm[2,0] * z)
        newy = (ctm[0,1] * x) + (ctm[1,1] * y) + (ctm[2,1] * z)

        [newx, newy]
      end

      # return a height of an image in the current device space. Auto
      # handles the translation from image space to device space.
      #
      def image_height
        bl_x, bl_y = transform(0, 0)
        tl_x, tl_y = transform(0, 1)

        min = [tl_y, bl_y].min
        max = [tl_y, bl_y].max
        max - min
      end

      # return a width of an image in the current device space. Auto
      # handles the translation from image space to device space.
      #
      def image_width
        bl_x, bl_y = transform(0, 0)
        br_x, br_y = transform(1, 0)

        min = [br_x, bl_x].min
        max = [br_x, bl_x].max
        max - min
      end

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
