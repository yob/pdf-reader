# coding: utf-8

class PDF::Reader

  # Takes a collection of TextRun objects and renders them into a single
  # string that best approximates the way they'd appear on a render PDF page.
  class PageLayout
    def initialize(runs, options = {})
      @runs    = merge_runs(runs)
      @options = options
      @current_platform_is_rbx_19 = RUBY_DESCRIPTION =~ /\Arubinius 2.0.0/ &&
                                      RUBY_VERSION >= "1.9.0"
    end

    def to_s
      row_count = @options.fetch(:number_of_rows, 100)
      col_count = @options.fetch(:number_of_cols, 200)
      row_multiplier = @options.fetch(:row_scale, 8.0) # 800
      col_multiplier = @options.fetch(:col_scale, 3.0) # 600
      x_offset = @runs.map(&:x).sort.first
      page = row_count.times.map { |i| " " * col_count }
      @runs.each do |run|
        x_pos = ((run.x - x_offset) / col_multiplier).round
        y_pos = row_count - (run.y / row_multiplier).round
        if y_pos < row_count && y_pos >= 0 && x_pos < col_count && x_pos >= 0
          local_string_insert(page[y_pos], run.text, x_pos)
        end
      end
      if @options.fetch(:strip_empty_lines, true)
        page = page.select { |line| line.strip.length > 0 }
      end
      page.map(&:rstrip).join("\n")
    end

    private

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
