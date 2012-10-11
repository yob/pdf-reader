# coding: utf-8

module PDF
  class Reader
    module Formatted
      module PageLayout

        # A TextGroup is create for every BT command, and contains all the lines of
        # text that are presented in that BeginText. This class implements a very
        # useful Simplify method that tries to reduce the line count by combining
        # lines that "run" into each other
        class TextGroup
          attr_reader :lines, :verbosity

          def initialize(verbosity = 0)
            @lines = []
            @verbosity = verbosity
          end

          def to_s
            value = ""
            @lines.each do |line|
              value << "| " << line.to_s
            end
          end

          def simplify()
            num_lines = self.lines.length
            current_line = nil
            lines_to_remove = []
            self.sorted_lines.each do |line|
              unless current_line
                current_line = line
              else
                if current_line.runs.size > 0
                  max_gap = 10 # points
                  fs_run = current_line.runs.last
                  fs_run ||= current_line.runs.first
                  puts "Current Line: #{current_line}Next Line: #{line}" if @verbosity > 2
                  puts "Current XMax: #{current_line.x_max} // #{line.position} == " +
                       "#{current_line.position} && #{(line.position.x - current_line.x_max).abs}" +
                       " < #{max_gap}\n" if @verbosity > 2
                  if (line.position.y - current_line.position.y).abs < fs_run.font_size &&
                    (line.position.x - current_line.x_max).abs < max_gap
                    line.runs.each do |run|
                      current_line.runs << run
                    end
                    lines_to_remove << line
                  else
                    current_line = line
                  end
                end
              end
            end
            lines_to_remove.each do |line_to_remove|
              self.lines.delete(line_to_remove)
            end
            puts "Reduced line count from #{num_lines} to #{self.lines.length}" if verbosity > 1
          end

          def sorted_lines
            # sort first by negative y, then positive x
            # pdf defines the lower left corner as 0
            self.lines.sort do |a, b|
              if a.position.y.round < b.position.y.round
                1
              elsif a.position.y.round > b.position.y.round
                -1
              elsif a.position.x.round < b.position.x.round
                -1
              elsif a.position.x.round > b.position.x.round
                1
              else
                0
              end
            end
          end
        end

        # A line is created for any number of Runs that are at the same y-position
        class Line
          attr_reader :position, :runs

          def initialize(position)
            @position = position
            @runs = []
          end

          def to_s
            value = sprintf("%s // %7.3f | '", self.position, self.x_max)
            @runs.each do |run|
              value += run.to_s
            end
            value += "'\n"
          end

          def inspect
            value = sprintf("%s // %7.3f |||\n'", self.position, self.x_max)
            @runs.each do |run|
              value << "#{run.inspect}\n"
            end
            value << "|||||||||||||||||\n"
          end

          # how wide this line of text is, measured in points
          def line_width
            width = 0.0
            @runs.each do |run|
              width += run.scaled_text_width
            end
            width
          end

          # the x position of the right-hand side of the line, measured in points
          def x_max
            self.line_width + self.position.x
          end

          # how many characters are in this line
          def num_of_characters
            self.runs.inject(0) do |char_count, run|
              char_count += run.utf8_text.size
              char_count
            end
          end

          # the text of this line
          def text
            text = ""
            self.runs.each do |run|
              text << run.utf8_text
            end
            text
          end

          # an indication as to whether or not this line is empty
          def is_empty?
            text.strip.length == 0
          end

          # the presumed font size of this line, there is nothing preventing
          # different font sizes in consecutive runs.
          def guess_font_size
            guessed_size = nil
            self.runs.each do |run|
              if run.utf8_text.strip.length > 0
                return run.font_size
              else
                guessed_size = run.font_size
              end
            end
            guessed_size
          end

          # the presumed font label of this line, there is nothing preventing
          # different font labels in consecutive runs.
          def guess_font_label
            guessed_label = nil
            self.runs.each do |run|
              if run.utf8_text.strip.length > 0
                return run.font_label
              else
                guessed_label = run.font_label
              end
            end
            guessed_label
          end

        end

        # A run of text, this can be either from a TJ or a Tj
        class Run
          attr_reader :source_text, :state, :page_state, :raw_text, :utf8_text, :font, :verbosity

          # Create a run with the passed text being either an array (from a TJ) or
          # a string (from a Tj), a state hash as defined in PDF::Reader::PageState,
          # a reference to the page_state (a PDF::Reader::PageState), mostly for obtaining
          # a reference to the correct font.
          def initialize(text, state, page_state, verbosity = 0)
            @source_text = text
            @state = state
            @page_state = page_state
            @font = page_state.find_font(@state[:text_font])
            @verbosity = verbosity
            @unscaled_text_width = nil
            @run = nil
            @total_kerning = 0
            if text.is_a? String
              @raw_text = text
            elsif text.is_a?(Enumerable) && text.length == 1
              @raw_text = text[0]
            elsif text.is_a? Enumerable
              # This is for TJ, take the elements out in pairs and pass them on to
              # determine how much kerning is involved. we won't be using the kerning
              # but we do need to know how much there is to properly adjust the width
              # of this run
              @raw_text = ""
              @run = []
              pair = text.shift(2)
              while pair.length > 0
                @run << pair
                process_kerning(pair)
                pair = text.shift(2)
              end
            else
              $stderr.puts "Don't know how to position #{text.inspect}"
            end
            # get the actual text in this run
            @utf8_text = font.to_utf8(@raw_text)
            puts "Run Created: #{self}" if verbosity > 2
          end

          # this is how wide this run is in Points
          def scaled_text_width
            self.unscaled_text_width() * self.font_size
          end

          # this is how wide this run is in Text Space
          def unscaled_text_width
            if @unscaled_text_width.nil?
              return unless @font.can_convert_to_utf8?
              tw = @font.width_of_fragment(@raw_text)
              puts "unscaled_text_width('#{@utf8_text}') = #{tw}" if @verbosity > 2
              tw ||= 0.0
              @unscaled_text_width = (tw - @total_kerning.to_f / 1000.0)
              if @state[:char_spacing] != 0.0
                # apply character spacing
                @unscaled_text_width += (@utf8_text.size - 1) * @state[:char_spacing]
              end
              if @state[:word_spacing] != 0.0
                # apply word spacing
                @unscaled_text_width += @utf8_text.count(' ') * @state[:word_spacing]
              end
              puts "Text Width: (#{tw} - #{@total_kerning} / 1000) = " +
              "#{@unscaled_text_width}" if @verbosity > 2
            end
            @unscaled_text_width
          end

          # the font size for this run
          def font_size
            @page_state.font_size
          end

          # the font label for this run
          def font_label
            @state[:text_font]
          end

          def inspect()
            sprintf("%25s @ %5.2f pt -- '%s'", @font.basefont, self.font_size, @utf8_text)
          end

          def to_s()
            @utf8_text
          end

          private

          # this method determines what is kerning and what is text, and shoves the
          # two into the right spots. There is no guarentee that there will be 2 elements
          # (there may be just one), nor is there any guarentee as to the order of
          # the elements ((text, kern) or (kern, text))
          def process_kerning(text_kern_pair)
            s = kern = nil
            if text_kern_pair.length == 2
              if text_kern_pair[0].is_a? String
                s, kern = text_kern_pair
              elsif text_kern_pair[0].is_a? Numeric
                kern, s = text_kern_pair
              end
            else
              if text_kern_pair[0].is_a? String
                s = text_kern_pair[0]
                kern = 0
              elsif text_kern_pair[0].is_a? Numeric
                kern = text_kern_pair[0]
                s = ""
              else
                $stderr.puts "unknown type in text/kern pair: #{text_kern_pair.inspect}"
              end
            end
            @raw_text << s
            @total_kerning += kern
          end

        end

        # an X,Y point in Cartesian space
        class Position
          attr_accessor :x, :y

          def initialize(x, y)
            @x = x
            @y = y
          end

          def to_s
            sprintf("{%7.3f, %7.3f}", @x, @y)
          end
        end
      end
    end
  end
end

