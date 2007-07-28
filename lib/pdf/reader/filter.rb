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
require 'zlib'

class PDF::Reader
  ################################################################################
  # Various parts of a PDF file can be passed through a filter before being stored to provide
  # support for features like compression and encryption. This class is for decoding that
  # content.
  #
  # Currently only 1 filter type is supported. Hopefully support for others will be added
  # in the future.
  class Filter
    ################################################################################
    # creates a new filter for decoding content
    def initialize (name, options)
      @options = options

      case name
      when "FlateDecode"    : @filter = :flate
      else                    raise "Unknown filter: #{name}"
      end
    end
    ################################################################################
    # attempts to decode the specified data with the current filter
    def filter (data)
      self.send(@filter, data)
    end
    ################################################################################
    # Decode the specified data with the Zlib compression algorithm
    def flate (data)
      z = Zlib::Inflate.new
      z << data
      z.inflate(nil)
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
