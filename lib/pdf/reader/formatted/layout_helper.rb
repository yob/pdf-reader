# coding: utf-8

module PDF
  class Reader
    module Formatted
      # Converts an object graph of text data into a UTF8 string
      class LayoutHelper
        attr_reader :lines, :verbosity, :options

        @tg = nil

        def initialize(options = {})
          @lines = []
          @options = options
          @verbosity = options.fetch(:verbosity, 0)
          @tg = PageLayout::TextGroup.new(@verbosity)
        end

        def lines
          @lines.clear
          puts "Attempting 1 more simplify before writing page" if @verbosity > 1
          @tg.simplify
          @lines.concat(@tg.lines)
        end

        def add_lines_from_text_group(text_group)
          text_group.sorted_lines.each do |line|
            @tg.lines << line
          end
        end

        def to_s
          def_rows = @options.fetch(:number_of_rows, 100)
          def_cols = @options.fetch(:number_of_cols, 200)
          row_multiplier = @options.fetch(:row_scale, 8.0) # 800
          col_multiplier = @options.fetch(:col_scale, 3.0) # 600
          page = []
          def_value = ""
          def_cols.times { def_value << " " }
          def_rows.times { page << String.new(def_value) }
          self.lines.each do |line|
            unless line.is_empty?
              x_pos = (line.position.x / col_multiplier).round
              y_pos = def_rows - (line.position.y / row_multiplier).round
              str = line.text
              if y_pos <= def_rows && y_pos >= 0 && x_pos <= def_cols && x_pos >= 0
                $stderr.puts "{%3d, %3d} -- %s" % [x_pos, y_pos, str.dump] if @verbosity > 2
                page[y_pos][Range.new(x_pos, x_pos + str.length - 1)] = String.new(str)
                $stderr.puts "Page[#{y_pos}] #{page[y_pos]}" if @verbosity > 2
              else
                $stderr.puts "Layout Skipping Line off of page:\n#{line}" if @verbosity > 0
              end
            else
              $stderr.puts "Layout Skipping Empty Line:\n#{line}" if @verbosity > 0
            end
          end
          final_string = ""
          strip_empty_lines = @options.fetch(:strip_empty_lines, true)
          page.each do |line|
            final_string << line.rstrip << "\n" unless line.strip.length == 0 && strip_empty_lines
          end
          final_string
        end

      end
    end
  end
end
