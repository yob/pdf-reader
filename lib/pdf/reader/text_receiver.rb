################################################################################
#
# Copyright (C) 2006 Peter J Jones (pjones@pmade.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################

class PDF::Reader
  ################################################################################
  # An example receiver class that processes all text found in a PDF file. All text that
  # is found will be printed to the IO object specified in the constructor.
  #
  # Usage:
  #  receiver = PDF::Reader::TextReceiver.new($stdout)
  #  PDF::Reader.file("somefile.pdf", receiver)
  class TextReceiver
    ################################################################################
    # Initialize with the library user's receiver
    def initialize (main_receiver)
      @main_receiver = main_receiver
      @upper_corners = []
    end
    ################################################################################
    # Called when the document parsing begins
    def begin_document (root)
      @upper_corners = []
    end
    ################################################################################
    # Called when the document parsing ends
    def end_document
      @state.clear
    end
    ################################################################################
    def begin_page_container (page)
      @upper_corners.push(media_box_check(page))
    end
    ################################################################################
    def end_page_container
      @upper_corners.pop
    end
    ################################################################################
    # Called when new page parsing begins
    def begin_page (info)
      @page = info

      @state = [{
        :char_spacing     => 0,
        :word_spacing     => 0,
        :hori_scaling     => 100,
        :leading          => 0,
        :tj_adjustment    => 0,
      }]

      @upper_corners.push(media_box_check(info))

      @output = []
      @line = 0
      @location = 0
      @displacement = {}
      @smallest_y_loc = @upper_corners.last[:ury]
      @written_to = false
    end
    ################################################################################
    # Called when page parsing ends
    def end_page
      @main_receiver << @output.join("\n")
      @upper_corners.pop
    end
    ################################################################################
    # PDF operator BT
    def begin_text_object
      @state.push(@state.last.dup)
    end
    ################################################################################
    # PDF operator ET
    def end_text_object
      @state.pop
    end
    ################################################################################
    # PDF operator Tm
    def set_text_matrix_and_text_line_matrix (*args)
      # these variable names look bad, but they're from the PDF spec
      a, b, c, d, e, f = *args
      calculate_line_and_location(f)
    end
    ################################################################################
    # PDF operator Tc
    def set_character_spacing (n)
      @state.last[:char_spacing] = n
    end
    ################################################################################
    # PDF operator Tw
    def set_word_spacing (n)
      @state.last[:word_spacing] = n
    end
    ################################################################################
    # PDF operator Tz
    def set_horizontal_text_scaling (n)
      @state.last[:hori_scaling] = n/100
    end
    ################################################################################
    # PDF operator TL
    def set_text_leading (n)
      @state.last[:leading] = n
    end
    ################################################################################
    # PDF operator T*
    def move_to_start_of_next_line
      move_text_position(0, @state.last[:leading])
    end
    ################################################################################
    # PDF operator Td
    def move_text_position (tx, ty)
      #puts "#{tx} #{ty} Td"
      calculate_line_and_location(@location + ty)
    end
    ################################################################################
    # PDF operator TD
    def move_text_position_and_set_leading (tx, ty)
      set_text_leading(ty)# * -1)
      move_text_position(tx, ty)
    end
    ################################################################################
    # PDF operator Tj
    def show_text (string)
      #puts "getting line #@line"

      place = (@output[@line] ||= "")
      #place << "  " unless place.empty?

      place << " " * (@state.last[:tj_adjustment].abs/900) if @state.last[:tj_adjustment] < -1000
      place << string

      #puts "place is now: #{place}"
      @written_to = true
    end
    def super_show_text (string)
      urx = @upper_corners.last[:urx]/TS_UNITS_PER_H_CHAR
      ury = @upper_corners.last[:ury]/TS_UNITS_PER_V_CHAR

      x = (@tm[2,0]/TS_UNITS_PER_H_CHAR).to_i
      y = (ury - (@tm[2,1]/TS_UNITS_PER_V_CHAR)).to_i
      
      #puts "rendering '#{string}' to #{x}x#{y}"

      place = (@output[y] ||= (" " * urx.to_i))
      #puts "#{urx} #{place.size} #{string.size} #{x}"
      return if x+string.size >= urx

      string.split(//).each do |c|
        chars = 1

        case c
        when " "
          chars += @state.last[:word_spacing].to_i
          place[x-1, chars] = (" " * chars)
        else
          chars += @state.last[:char_spacing].to_i
          chars -= (@state.last[:tj_adjustment]/1000).to_i if @state.last[:tj_adjustment]
          chars = 1 if chars < 1

          place[x-1] = c
          place[x, chars-1] = (" " * (chars-1)) if chars > 1
        end

        x += chars
      end

      @tm += Matrix.rows([[1, 0, 0], [0, 1, 0], [x*TS_UNITS_PER_H_CHAR, y*TS_UNITS_PER_V_CHAR, 1]])
    end
    ################################################################################
    # PDF operator TJ
    def show_text_with_positioning (params)
      prev_adjustment = @state.last[:tj_adjustment]

      params.each do |p|
        case p
        when Float, Fixnum
          @state.last[:tj_adjustment] = p
        else
          show_text(p)
        end
      end

      @state.last[:tj_adjustment]  = prev_adjustment
    end
    ################################################################################
    # PDF operator '
    def move_to_next_line_and_show_text (string)
      move_to_start_of_next_line
      show_text(string)
    end
    ################################################################################
    # PDF operator "
    def set_spacing_next_line_show_text (aw, ac, string)
      set_word_spacing(aw)
      set_character_spacing(ac)
      move_to_next_line_and_show_text(string)
    end
    ################################################################################
    def media_box_check (dict)
      corners = (@upper_corners.last || {:urx => 0, :ury => 0}).dup

      if dict.has_key?(:MediaBox)
        media_box = dict[:MediaBox]
        corners[:urx] = media_box[2] - media_box[0]
        corners[:ury] = media_box[3] - media_box[1]
      end

      corners
    end
    ################################################################################
    def calculate_line_and_location (new_loc)
      ##puts "calculate_line_and_location(#{new_loc})"
      key = new_loc; key.freeze

      #key = new_loc.to_s # because hashes with string keys are magic (auto-freeze)

      if @written_to
        unless @displacement.has_key?(key)
          if key < @location
            @displacement[key] = @line + 1
          elsif key < @smallest_y_loc
            @displacement[key] = @line + 1
          else
            key = @displacement.keys.find_all {|i| key > i}.sort.last
            @displacement[key] = 0 unless @displacement.has_key?(key)
          end
        end
      else
        @displacement[key] = 0
      end

      @smallest_y_loc = key if key < @smallest_y_loc
      @location = key
      @line = @displacement[key]
      #puts "calculate_line_and_location: @location=#@location @line=#@line smallest_y_loc=#@smallest_y_loc"
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
