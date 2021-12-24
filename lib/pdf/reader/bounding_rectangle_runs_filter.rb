# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader

  # Filter our text/characters that are positioned outside a rectangle. Usually the page
  # MediaBox or CropBox, but could be a user specified rectangle too
  class BoundingRectangleRunsFilter

    def self.runs_within_rect(runs, rect)
      runs.select { |run| rect.contains?(run.origin) }
    end
  end
end

