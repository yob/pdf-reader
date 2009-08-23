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
    # creates a new filter for decoding content.
    #
    # Filters that are only used to encode image data are accepted, but the data is
    # returned untouched. At this stage PDF::Reader has no need to decode images.
    #
    def initialize (name, options)
      @options = options

      case name.to_sym
      when :FlateDecode    then @filter = :flate
      when :DCTDecode      then @filter = nil
      when :JBIG2Decode    then @filter = nil
      else                 raise UnsupportedFeatureError, "Unknown filter: #{name}"
      end
    end
    ################################################################################
    # attempts to decode the specified data with the current filter
    #
    # Filters that are only used to encode image data are accepted, but the data is
    # returned untouched. At this stage PDF::Reader has no need to decode images.
    #
    def filter (data)
      # leave the data untouched if we don't support the required filter
      return data if @filter.nil?

      # decode the data
      self.send(@filter, data)
    end
    ################################################################################
    # Decode the specified data with the Zlib compression algorithm
    def flate (data)
      begin
        Zlib::Inflate.new.inflate(data)
      rescue Zlib::DataError => e
        # by default, Ruby's Zlib assumes the data it's inflating
        # is RFC1951 deflated data, wrapped in a RFC1951 zlib container.
        # If that fails, then use an undocumented 'feature' to attempt to inflate
        # the data as a raw RFC1951 stream.
        #
        # See
        # - http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/243545
        # - http://www.gzip.org/zlib/zlib_faq.html#faq38
        Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(data)
      end
    rescue Exception => e
      # Oops, there was a problem inflating the stream
      raise MalformedPDFError, "Error occured while inflating a compressed stream (#{e.class.to_s}: #{e.to_s})"
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
