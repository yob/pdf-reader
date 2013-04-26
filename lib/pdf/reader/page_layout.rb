# coding: utf-8

class PDF::Reader

  # Takes a collection of TextRun objects and renders them into a single
  # string that best approximates the way they'd appear on a render PDF page.
  #
  # media box should be a 4 number array that describes the dimensions of the
  # page to be rendered as described by the page's MediaBox attribute
  class PageLayout

    WHITE_SPACE_REGEX = /^\s*$/

    def initialize(runs, mediabox, page_layout_opts = {})
      raise ArgumentError, "a mediabox must be provided" if mediabox.nil?

      @runs    = runs
      @mean_font_size   = mean(@runs.map(&:font_size)) || 0
      @mean_glyph_width = mean(@runs.map(&:mean_character_width)) || 0
      @page_width  = mediabox[2] - mediabox[0]
      @page_height = mediabox[3] - mediabox[1]
      @layout_opts = {:col_multiplication_factor => 1.05}.merge page_layout_opts
      @x_offset = @runs.map(&:x).sort.first
      @current_platform_is_rbx_19 = RUBY_DESCRIPTION =~ /\Arubinius 2.0.0/ &&
                                      RUBY_VERSION >= "1.9.0"
    end

    def to_s
      return "" if @runs.empty?

      page = row_count.times.map { |i| " " * col_count }
      @runs.each do |run|
        x_pos = ((run.x - @x_offset) / col_multiplier).round
        y_pos = row_count - (run.y / row_multiplier).round
        if y_pos < row_count && y_pos >= 0 && x_pos < col_count && x_pos >= 0
          local_string_insert(page[y_pos], run.text, x_pos)
        end
      end
      interesting_rows(page).map(&:rstrip).join("\n")
    end

    private

    # given an array of strings, return a new array with empty rows from the
    # beginning and end removed.
    #
    #   interesting_rows([ "", "one", "two", "" ])
    #   => [ "one", "two" ]
    #
    def interesting_rows(rows)
      line_lengths = rows.map { |l| l.strip.length }
      first_line_with_text = line_lengths.index { |l| l > 0 }
      last_line_with_text  = line_lengths.size - line_lengths.reverse.index { |l| l > 0 }
      interesting_line_count = last_line_with_text - first_line_with_text
      rows[first_line_with_text, interesting_line_count].map
    end

    def row_count
      @row_count ||= (@page_height / @mean_font_size).floor
    end

    def col_count
      @col_count ||= ((@page_width  / @mean_glyph_width) * @layout_opts[:col_multiplication_factor]).floor
    end

    def row_multiplier
      @row_multiplier ||= @page_height.to_f / row_count.to_f
    end

    def col_multiplier
      @col_multiplier ||= @page_width.to_f / col_count.to_f
    end

    def mean(collection)
      if collection.size == 0
        0
      else
        collection.inject(0) { |accum, v| accum + v} / collection.size.to_f
      end
    end

    def each_line(&block)
      @runs.sort.group_by { |run|
        run.y.to_i
      }.map { |y, collection|
        yield y, collection
      }
    end

    # This is a simple alternative to String#[]=. We can't use the string
    # method as it's buggy on rubinius 2.0rc1 (in 1.9 mode)
    #
    # See my bug report at https://github.com/rubinius/rubinius/issues/1985
    def local_string_insert(haystack, needle, index)
      # hopefully String#[] is not buggy only String#[]=
      if !(haystack[Range.new(index, index + needle.length - 1)] =~ WHITE_SPACE_REGEX)
        $stderr.puts "Warning overwriting one or more characters while laying out text, " +
          "col_multiplication_factor (currently #{@layout_opts[:col_multiplication_factor]}) " +
          "should be increased to avoid this."
      end
      if @current_platform_is_rbx_19
        char_count = needle.length
        haystack.replace(
          (haystack[0,index] || "") +
          needle +
          (haystack[index+char_count,500] || "")
        )
      else
        haystack[Range.new(index, index + needle.length - 1)] = String.new(needle)
      end
    end
  end
end
