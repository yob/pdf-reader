# coding: utf-8
# typed: strict
# frozen_string_literal: true

require 'pdf/reader/overlapping_runs_filter'
require 'pdf/reader/zero_width_runs_filter'

class PDF::Reader

  # Takes a collection of TextRun objects and renders them into a single
  # string that best approximates the way they'd appear on a render PDF page.
  #
  # media box should be a 4 number array that describes the dimensions of the
  # page to be rendered as described by the page's MediaBox attribute
  class PageLayout

    DEFAULT_FONT_SIZE = 12

    def initialize(runs, mediabox)
      # mediabox is a 4-element array for now, but it'd be nice to switch to a
      # PDF::Reader::Rectangle at some point
      PDF::Reader::Error.validate_not_nil(mediabox, "mediabox")

      @mediabox = process_mediabox(mediabox)
      @runs = runs
      @mean_font_size   = mean(@runs.map(&:font_size)) || DEFAULT_FONT_SIZE
      @mean_font_size = DEFAULT_FONT_SIZE if @mean_font_size == 0
      @median_glyph_width = median(@runs.map(&:mean_character_width)) || 0
      @x_offset = @runs.map(&:x).sort.first || 0
      lowest_y = @runs.map(&:y).sort.first || 0
      @y_offset = lowest_y > 0 ? 0 : lowest_y
    end

    def to_s
      return "" if @runs.empty?
      return "" if row_count == 0

      page = row_count.times.map { |i| " " * col_count }
      @runs.each do |run|
        x_pos = ((run.x - @x_offset) / col_multiplier).round
        y_pos = row_count - ((run.y - @y_offset) / row_multiplier).round
        if y_pos <= row_count && y_pos >= 0 && x_pos <= col_count && x_pos >= 0
          local_string_insert(page[y_pos-1], run.text, x_pos)
        end
      end
      interesting_rows(page).map(&:rstrip).join("\n")
    end

    private

    def page_width
      @mediabox.width
    end

    def page_height
      @mediabox.height
    end

    # given an array of strings, return a new array with empty rows from the
    # beginning and end removed.
    #
    #   interesting_rows([ "", "one", "two", "" ])
    #   => [ "one", "two" ]
    #
    def interesting_rows(rows)
      line_lengths = rows.map { |l| l.strip.length }

      return [] if line_lengths.all?(&:zero?)

      first_line_with_text = line_lengths.index { |l| l > 0 }
      last_line_with_text  = line_lengths.size - line_lengths.reverse.index { |l| l > 0 }
      interesting_line_count = last_line_with_text - first_line_with_text
      rows[first_line_with_text, interesting_line_count].map
    end

    def row_count
      @row_count ||= (page_height / @mean_font_size).floor
    end

    def col_count
      @col_count ||= ((page_width  / @median_glyph_width) * 1.05).floor
    end

    def row_multiplier
      @row_multiplier ||= page_height.to_f / row_count.to_f
    end

    def col_multiplier
      @col_multiplier ||= page_width.to_f / col_count.to_f
    end

    def mean(collection)
      if collection.size == 0
        0
      else
        collection.inject(0) { |accum, v| accum + v} / collection.size.to_f
      end
    end

    def median(collection)
      if collection.size == 0
        0
      else
        collection.sort[(collection.size * 0.5).floor]
      end
    end

    def local_string_insert(haystack, needle, index)
      haystack[Range.new(index, index + needle.length - 1)] = String.new(needle)
    end

    def process_mediabox(mediabox)
      if mediabox.is_a?(Array)
        msg = "Passing the mediabox to PageLayout as an Array is deprecated," +
          " please use a Rectangle instead"
        $stderr.puts msg
        PDF::Reader::Rectangle.from_array(mediabox)
      else
        mediabox
      end
    end

  end
end
