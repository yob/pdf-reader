# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader
  # There's no point rendering zero-width characters
  class ZeroWidthRunsFilter

    #: (Array[PDF::Reader::TextRun]) -> Array[PDF::Reader::TextRun]
    def self.exclude_zero_width_runs(runs)
      runs.reject { |run| run.width == 0 }
    end
  end
end
