# coding: utf-8

class PDF::Reader
  # There's no point rendering zero-width characters
  class ZeroWidthRunsFilter

    def self.exclude_zero_width_runs(runs)
      runs.reject { |run| run.width == 0 }
    end
  end
end
