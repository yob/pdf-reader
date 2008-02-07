################################################################################
#
# Copyright (C) 2008 James Healy (jimmy@deefa.com)
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
  class CMap

    def initialize(data)
      @map = {}
      inmap = false
      data.each_line do |l|
        inmap = true if l.include?("beginbfchar")
        if inmap
          m, find, replace = *l.match(/<([0-9a-f]+)> <([0-9a-f]+)>/)
          @map[hex_str_to_int(find)] = hex_str_to_int(replace) if find && replace
        end
      end
    end

    def decode(c)
      # TODO: implement the conversion
      Error.assert_equal(c.class, Fixnum)
      @map[c]
    end

    private

    def hex_str_to_int(str)
      str.downcase!
      num = 0
      counter = 1
      str.reverse.each_byte do |c|
        if c <= 57 
          c = c - 48
        elsif c <= 102
          c = c - 87
        end

        num += (c * counter)
        if counter == 1
          counter = 16
        else
          counter *= 16
        end
      end
      num
    end
  end
end
