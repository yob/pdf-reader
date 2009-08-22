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
  # An internal PDF::Reader class that mediates access to the underlying PDF File or IO Stream
  class Buffer
    ################################################################################
    # Creates a new buffer around the specified IO object
    def initialize (io)
      @io = io
      @buffer = nil
    end
    ################################################################################
    # Seek to the requested byte in the IO stream.
    def seek (offset)
      @io.seek(offset, IO::SEEK_SET)
      @buffer = nil
      self
    end
    ################################################################################
    # reads the requested number of bytes from the underlying IO stream. 
    #
    # length should be a positive integer.
    def read (length)
      out = ""

      if @buffer and !@buffer.empty?
        out << head(length)
        length -= out.length
      end

      out << @io.read(length) if length > 0
      out
    end
    ################################################################################
    # Reads from the buffer until the specified token is found, or the end of the buffer 
    #
    # bytes - the bytes to search for.
    def read_until(bytes)
      out = ""
      size = bytes.size
       
      loop do
        out << @io.read(1)
        if out[-1 * size,size].eql?(bytes)
          out = out[0, out.size - size]
          seek(pos - size)
          break
        end
      end
      out
    end
    ################################################################################
    # returns true if the underlying IO object is at end and the internal buffer 
    # is empty
    def eof?
      ready_token
      if @buffer
        @buffer.empty? && @io.eof?
      else
        @io.eof?
      end
    end
    ################################################################################
    def pos
      @io.pos
    end
    ################################################################################
    def pos_without_buf
      @io.pos - @buffer.to_s.size
    end
    ################################################################################
    # PDF files are processed by tokenising the content into a series of objects and commands.
    # This prepares the buffer for use by reading the next line of tokens into memory.
    def ready_token (with_strip=true, skip_blanks=true)
      while (@buffer.nil? or @buffer.empty?) && !@io.eof?
        @buffer = @io.readline
        @buffer.force_encoding("BINARY") if @buffer.respond_to?(:force_encoding)
        #@buffer.sub!(/%.*$/, '') if strip_comments
        @buffer.chomp!
        break unless skip_blanks
      end
      @buffer.lstrip! if with_strip
    end
    ################################################################################
    # return the next token from the underlying IO stream
    def token
      ready_token
      
      i = @buffer.index(/[\[\]()<>{}\s\/]/) || @buffer.size

      token_chars = 
        if i == 0 and @buffer[i,2] == "<<"    then 2
        elsif i == 0 and @buffer[i,2] == ">>" then 2
        elsif i == 0                          then 1
        else                                    i
        end

      strip_space = !(i == 0 and @buffer[0,1] == '(')
      tok = head(token_chars, strip_space)

      if tok == ""
        nil
      elsif tok[0,1] == "%"
        @buffer = ""
        token
      else
        tok
      end
    end
    ################################################################################
    def head (chars, with_strip=true)
      val = @buffer[0, chars]
      @buffer = @buffer[chars .. -1] || ""
      @buffer.lstrip! if with_strip
      val
    end
    ################################################################################
    # return the internal buffer used by this class when reading from the IO stream.
    def raw
      @buffer
    end
    ################################################################################
    # The Xref table in a PDF file acts as an aid for finding the location of various
    # objects in the file. This method attempts to locate the byte offset of the xref
    # table in the underlying IO stream.
    def find_first_xref_offset
      @io.seek(-1024, IO::SEEK_END) rescue seek(0)
      data = @io.read(1024)

      # the PDF 1.7 spec (section #3.4) says that EOL markers can be either \r, \n, or both.
      # To ensure we find the xref offset correctly, change all possible options to a 
      # standard format
      data = data.gsub("\r\n","\n").gsub("\n\r","\n").gsub("\r","\n")
      lines = data.split(/\n/).reverse

      eof_index = nil

      lines.each_with_index do |line, index|
        if line =~ /^%%EOF\r?$/
          eof_index = index
          break
        end
      end

      raise MalformedPDFError, "PDF does not contain EOF marker" if eof_index.nil?
      raise MalformedPDFError, "PDF EOF marker does not follow offset" if eof_index >= lines.size-1
      lines[eof_index+1].to_i
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################
