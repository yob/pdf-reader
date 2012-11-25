# coding: utf-8

class PDF::Reader

  # Takes a collection of TextRun objects and renders them into a single
  # string that best approximates the way they'd appear on a render PDF page.
  class PageLayout
    def initialize(runs)
      @mean_font_size   = mean(runs.map(&:font_size)) || 0
      @mean_glyph_width = mean(runs.map {|r| r.width / r.text.unpack("U*").size.to_f}) || 0
      @runs    = merge_runs(runs)
      @current_platform_is_rbx_19 = RUBY_DESCRIPTION =~ /\Arubinius 2.0.0/ &&
                                      RUBY_VERSION >= "1.9.0"
    end

    def to_s
      return "" if @runs.empty?

      page_width  = 595.28
      page_height = 841.89
      row_count   = (page_height / @mean_font_size).floor
      col_count   = ((page_width  / @mean_glyph_width) * 1.05).floor
      row_multiplier = page_height / row_count
      col_multiplier = page_width / col_count
      x_offset = @runs.map(&:x).sort.first
      page = row_count.times.map { |i| " " * col_count }
      @runs.each do |run|
        x_pos = ((run.x - x_offset) / col_multiplier).round
        y_pos = row_count - (run.y / row_multiplier).round
        if y_pos < row_count && y_pos >= 0 && x_pos < col_count && x_pos >= 0
          local_string_insert(page[y_pos], run.text, x_pos)
        end
      end
      line_lengths = page.map { |l| l.strip.length }
      first_line_with_text = line_lengths.index { |l| l > 0 }
      last_line_with_text  = line_lengths.size - line_lengths.reverse.index { |l| l > 0 }
      interesting_line_count = last_line_with_text - first_line_with_text
      page[first_line_with_text, interesting_line_count].map(&:rstrip).join("\n")
    end

    private

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

    # take a collection of TextRun objects and merge any that are in close
    # proximity
    def merge_runs(runs)
      runs.group_by { |char|
        char.y.to_i
      }.map { |y, chars|
        group_chars_into_runs(chars.sort)
      }.flatten.sort
    end

    def group_chars_into_runs(chars)
      runs = []
      while head = chars.shift
        if runs.empty?
          runs << head
        elsif runs.last.mergable?(head)
          runs[-1] = runs.last + head
        else
          runs << head
        end
      end
      runs
    end

    # This is a simple alternative to String#[]=. We can't use the string
    # method as it's buggy on rubinius 2.0rc1 (in 1.9 mode)
    #
    # See my bug report at https://github.com/rubinius/rubinius/issues/1985
    def local_string_insert(haystack, needle, index)
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
