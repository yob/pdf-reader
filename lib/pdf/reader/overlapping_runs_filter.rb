# coding: utf-8

class PDF::Reader
  # remove duplicates from a collection of TextRun objects. This can be helpful when a PDF
  # uses slightly offset overlapping characters to achieve a fake 'bold' effect.
  class OverlappingRunsFilter

    # This should be between 0 and 1. If TextRun B obscures this much of TextRun A (and they
    # have identical characters) then one will be discarded
    OVERLAPPING_PERCENTAGE_THRESHOLD = 0.5

    def self.exclude_redundant_runs(runs)
      collection = new_marked_text_run_collection(runs)
      collection.each do |run|
        next unless run.keep?

        collection.reject { |comp|
          run.object_id == comp.object_id
        }.select { |comp|
          comp.keep? &&
            run.text == comp.text &&
            run.intersection_area_percent(comp) > OVERLAPPING_PERCENTAGE_THRESHOLD
        }.each { |comp|
          comp.discard!
        }
      end
      return_umarked_items(collection)
    end

    def self.new_marked_text_run_collection(runs)
      runs.map { |run| MarkedTextRun.new(run) }
    end

    def self.return_umarked_items(collection)
      collection.select { |run|
        run.keep?
      }.map(&:run)
    end

  end

  # Utility class used to avoid modifying the underlying TextRun objects while we're
  # looking for duplicates
  class MarkedTextRun
    attr_reader :run

    def initialize(run)
      @run = run
      @discard = false
    end

    def discard!
      @discard = true
    end

    def keep?
      !@discard
    end

    def text
      @run.text
    end

    def intersection_area_percent(comp)
      @run.intersection_area_percent(comp.run)
    end
  end
end
