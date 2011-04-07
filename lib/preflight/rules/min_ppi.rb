# coding: utf-8

module Preflight
  module Rules

    # For high quality prints, you generally want raster images to be
    # AT LEAST 300 points-per-inch (ppi). 600 is better, 1200 better again.
    #
    class MinPpi
      include Preflight::Measurements

      attr_reader :messages

      def initialize(min_ppi)
        @min_ppi = min_ppi.to_i
        @messages = []
        @last_matrix = []
        @page_num = 0
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

      # track the most recent matrix transform.
      #
      # TODO: This needs to be smarter at tracking the graphics state stack
      #
      def concatenate_matrix(*args)
        @last_matrix = args
      end

      # As each image is drawn on the canvas, determine the amount of device
      # space it's being crammed into and therefore the PPI.
      #
      def invoke_xobject(label)
        return unless @images[label]

        sample_w, sample_h = *@images[label]
        device_w = pt2in(@last_matrix[0])
        device_h = pt2in(@last_matrix[3])

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
      end
    end
  end
end
