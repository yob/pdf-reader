# coding: utf-8
# typed: strict
# frozen_string_literal: true

class PDF::Reader
  # There's no point rendering zero-width characters
  class NoTextFilter

    def self.exclude_empty_strings(runs)
      runs.reject { |run| run.text.to_s.size == 0 }
    end
  end
end

