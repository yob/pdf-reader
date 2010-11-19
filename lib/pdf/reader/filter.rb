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
  class Filter # :nodoc:
    ################################################################################
    # creates a new filter for decoding content.
    #
    # Filters that are only used to encode image data are accepted, but the data is
    # returned untouched. At this stage PDF::Reader has no need to decode images.
    #
    def initialize (name, options = nil)
      @options = options

      case name.to_sym
      when :ASCII85Decode  then @filter = :ascii85
      when :ASCIIHexDecode then @filter = :asciihex
      when :CCITTFaxDecode then @filter = nil
      when :DCTDecode      then @filter = nil
      when :FlateDecode    then @filter = :flate
      when :JBIG2Decode    then @filter = nil
      when :LZWDecode      then @filter = :lzw
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
    # Decode the specified data using the Ascii85 algorithm. Relies on the AScii85
    # rubygem.
    #
    def ascii85(data)
      data = "<~#{data}" unless data.to_s[0,2] == "<~"
      Ascii85::decode(data)
    rescue Exception => e
      # Oops, there was a problem decoding the stream
      raise MalformedPDFError, "Error occured while decoding an ASCII85 stream (#{e.class.to_s}: #{e.to_s})"
    end
    ################################################################################
    # Decode the specified data using the AsciiHex algorithm.
    #
    def asciihex(data)
      data.chop! if data[-1,1] == ">"
      data = data[1,data.size] if data[0,1] == "<"
      data.gsub!(/[^A-Fa-f0-9]/,"")
      data << "0" if data.size % 2 == 1
      data.scan(/.{2}/).map { |s| s.hex.chr }.join("")
    rescue Exception => e
      # Oops, there was a problem decoding the stream
      raise MalformedPDFError, "Error occured while decoding an ASCIIHex stream (#{e.class.to_s}: #{e.to_s})"
    end
    ################################################################################
    # Decode the specified data with the Zlib compression algorithm
    def flate (data)
      deflated = nil
      begin
        deflated = Zlib::Inflate.new.inflate(data)
      rescue Zlib::DataError => e
        # by default, Ruby's Zlib assumes the data it's inflating
        # is RFC1951 deflated data, wrapped in a RFC1951 zlib container.
        # If that fails, then use an undocumented 'feature' to attempt to inflate
        # the data as a raw RFC1951 stream.
        #
        # See
        # - http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/243545
        # - http://www.gzip.org/zlib/zlib_faq.html#faq38
        deflated = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(data)
      end
      depredict(deflated, @options)
    rescue Exception => e
      # Oops, there was a problem inflating the stream
      raise MalformedPDFError, "Error occured while inflating a compressed stream (#{e.class.to_s}: #{e.to_s})"
    end
    ################################################################################
    # Decode the specified data with the LZW compression algorithm
    def lzw(data)
      data = PDF::Reader::LZW.decode(data)
      depredict(data, @options)
    end
    ################################################################################
    def depredict(data, opts = {})
      predictor = (opts || {})[:Predictor].to_i

      case predictor
      when 0, 1 then
        data
      when 2    then
        tiff_depredict(data, opts)
      when 10, 11, 12, 13, 14, 15 then
        png_depredict(data, opts)
      else
        raise  MalformedPDFError, "Unrecognised predictor value (#{predictor})"
      end
    end
    ################################################################################
    def tiff_depredict(data, opts = {})
      raise UnsupportedFeatureError, "TIFF predictor not supported"
    end
    ################################################################################
    def png_depredict(data, opts = {})
      return data if opts.nil? || opts[:Predictor].to_i < 10

      data = data.unpack("C*")

      pixel_bytes     = 1 #pixel_bitlength / 8
      scanline_length = (pixel_bytes * opts[:Columns]) + 1
      row = 0
      pixels = []
      paeth, pa, pb, pc = nil
      until data.empty? do
        row_data = data.slice! 0, scanline_length
        filter = row_data.shift
        case filter
        when 0 # None
        when 1 # Sub
          row_data.each_with_index do |byte, index|
            left = index < pixel_bytes ? 0 : row_data[index - pixel_bytes]
            row_data[index] = (byte + left) % 256
            #p [byte, left, row_data[index]]
          end
        when 2 # Up
          row_data.each_with_index do |byte, index|
            col = index / pixel_bytes
            upper = row == 0 ? 0 : pixels[row-1][col][index % pixel_bytes]
            row_data[index] = (upper + byte) % 256
          end
        when 3  # Average
          row_data.each_with_index do |byte, index|
            col = index / pixel_bytes
            upper = row == 0 ? 0 : pixels[row-1][col][index % pixel_bytes]
            left = index < pixel_bytes ? 0 : row_data[index - pixel_bytes]

            row_data[index] = (byte + ((left + upper)/2).floor) % 256
          end
        when 4 # Paeth
          left = upper = upper_left = nil
          row_data.each_with_index do |byte, index|
            col = index / pixel_bytes

            left = index < pixel_bytes ? 0 : row_data[index - pixel_bytes]
            if row.zero?
              upper = upper_left = 0
            else
              upper = pixels[row-1][col][index % pixel_bytes]
              upper_left = col.zero? ? 0 :
                pixels[row-1][col-1][index % pixel_bytes]
            end

            p = left + upper - upper_left
            pa = (p - left).abs
            pb = (p - upper).abs
            pc = (p - upper_left).abs

            paeth = if pa <= pb && pa <= pc
                      left
                    elsif pb <= pc
                      upper
                    else
                      upper_left
                    end

            row_data[index] = (byte + paeth) % 256
          end
        else
          raise ArgumentError, "Invalid filter algorithm #{filter}"
        end

        s = []
        row_data.each_slice pixel_bytes do |slice|
          s << slice
        end
        pixels << s
        row += 1
      end

      pixels.map { |row| row.flatten.pack("C*") }.join("")
    end
  end
end
################################################################################
