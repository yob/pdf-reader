# coding: utf-8

################################################################################
#
# Copyright (C) 2010 James Healy (jimmy@deefa.com)
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

  # A string tokeniser that recognises PDF grammar. When passed an IO stream or a
  # string, repeated calls to token() will return the next token from the source.
  #
  # This is very low level, and getting the raw tokens is not very useful in itself.
  #
  # This will usually be used in conjunction with PDF:Reader::Parser, which converts
  # the raw tokens into objects we can work with (strings, ints, arrays, etc)
  #
  class Buffer

    attr_reader :pos

    # Creates a new buffer.
    #
    # Params:
    #
    #   io - an IO stream or string with the raw data to tokenise
    #
    # options:
    #
    #   :seek - a byte offset to seek to before starting to tokenise
    #
    def initialize (io, opts = {})
      @io = io
      @tokens = []
      @options = opts

      @io.seek(opts[:seek]) if opts[:seek]
      @pos = @io.pos
    end

    # return true if there are no more tokens left
    #
    def empty?
      prepare_tokens if @tokens.size < 3

      @tokens.empty?
    end

    # return raw bytes from the underlying IO stream.
    #
    #   bytes - the number of bytes to read
    #
    # options:
    #
    #   :skip_eol - if true, the IO stream is advanced past any LF or CR
    #               bytes before it reads any data. This is to handle
    #               content streams, which have a CRLF or LF after the stream
    #               token.
    #
    def read(bytes, opts = {})
      reset_pos

      if opts[:skip_eol]
        done = false
        while !done
          chr = @io.read(1)
          if chr.nil?
            return nil
          elsif chr != "\n" && chr != "\r"
            @io.seek(-1, IO::SEEK_CUR)
            done = true
          end
        end
      end

      bytes = @io.read(bytes)
      save_pos
      bytes
    end

    # return raw bytes from the underlying IO stream. All bytes up to the first
    # occurrence of needle will be returned. The match (if any) is not returned.
    # The IO stream cursor is left on the first byte of the match.
    #
    #   needle - a string to search the IO stream for
    #
    def read_until(needle)
      reset_pos
      out = ""
      size = needle.size

      while out[size * -1, size] != needle && !@io.eof?
        out << @io.read(1)
      end

      if out[size * -1, size] == needle
        out = out[0, out.size - size]
        @io.seek(size * -1, IO::SEEK_CUR)
      end

      save_pos
      out
    end

    # return the next token from the source. Returns a string if a token
    # is found, nil if there are no tokens left.
    #
    def token
      reset_pos
      prepare_tokens if @tokens.size < 3
      merge_indirect_reference
      prepare_tokens if @tokens.size < 3

      @tokens.shift
    end

    # return the byte offset where the first XRef table in th source can be found.
    #
    def find_first_xref_offset
      @io.seek(-1024, IO::SEEK_END) rescue @io.seek(0)
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

    private

    # Some bastard moved our IO stream cursor. Restore it.
    #
    def reset_pos
      @io.seek(@pos) if @io.pos != @pos
    end

    # save the current position of the source IO stream. If someone else (like another buffer)
    # moves the cursor, we can then restore it.
    #
    def save_pos
      @pos = @io.pos
    end

    # attempt to prime the buffer with the next few tokens.
    #
    def prepare_tokens
      10.times do
        if state == :literal_string
          prepare_literal_token
        elsif state == :regular
          prepare_regular_token
        end
      end

      save_pos
    end

    # tokenising behaves slightly differently based on the current context.
    # Determine the current context/state by examining the last token we found
    #
    def state
      if @tokens[-1] == "("
        :literal_string
      elsif @tokens[-1] == "stream"
        :stream
      else
        :regular
      end
    end

    # detect a series of 3 tokens that make up an indirect object. If we find
    # them, replace the tokens with a PDF::Reader::Reference instance.
    #
    # Merging them into a single string was another option, but that would mean
    # code further up the stack would need to check every token  to see if it looks
    # like an indirect object. For optimisation reasons, I'd rather avoid
    # that extra check.
    #
    # It's incredibly likely that the next 3 tokens in the buffer are NOT an
    # indirect reference, so test for that case first and avoid the relatively
    # expensive regexp checks if possible.
    #
    def merge_indirect_reference
      return if @tokens.size < 3
      return if @tokens[2] != "R"

      if @tokens[0].match(/\d+/) && @tokens[1].match(/\d+/)
        @tokens[0] = PDF::Reader::Reference.new(@tokens[0].to_i, @tokens[1].to_i)
        @tokens[1] = nil
        @tokens[2] = nil
        @tokens.compact!
      end
    end

    # if we're currently inside a literal string we more or less just read bytes until
    # we find the closing ) delimiter. Lots of bytes that would otherwise indicate the
    # start of a new token in regular mode are left untouched when inside a literal
    # string.
    #
    # The entire literal string will be returned as a single token. It will need further
    # processing to fix things like escaped new lines, but that's someone else's
    # problem.
    #
    def prepare_literal_token
      str = ""
      count = 1

      while count > 0
        chr = @io.read(1)
        if chr.nil?
          count = 0 # unbalanced params
        elsif chr == "(" && str[-1,1] != "\x5C"
          str << "("
          count += 1
        elsif chr == ")" && str[-1,1] != "\x5C"
          count -= 1
          str << ")" unless count == 0
        else
          str << chr unless count == 0
        end
      end

      @tokens << str if str.size > 0
      @tokens << ")"
    end

    # Extract the next regular token and stock it in our buffer, ready to be returned.
    #
    # What each byte means is complex, check out section "3.1.1 Character Set" of the 1.7 spec
    # to read up on it.
    #
    def prepare_regular_token
      tok = ""

      while chr = @io.read(1)
        case chr
        when "\x25"
          # comment, ignore everything until the next EOL char
          done = false
          while !done
            chr = @io.read(1)
            done = true if chr.nil? || chr == "\x0A" || chr == "\x0D"
          end
        when "\x00", "\x09", "\x0A", "\x0C", "\x0D", "\x20"
          # white space, token finished
          @tokens << tok if tok.size > 0
          tok = ""
          break
        when "\x3C"
          # opening delimiter '<', start of new token
          @tokens << tok if tok.size > 0
          chr << @io.read(1) if peek_char == "\x3C" # check if token is actually '<<'
          @tokens << chr
          tok = ""
          break
        when "\x3E"
          # closing delimiter '>', start of new token
          @tokens << tok if tok.size > 0
          chr << @io.read(1) if peek_char == "\x3E" # check if token is actually '>>'
          @tokens << chr
          tok = ""
          break
        when "\x28", "\x5B", "\x7B", "\x2F"
          # opening delimiter, start of new token
          @tokens << tok if tok.size > 0
          @tokens << chr
          tok = ""
          break
        when "\x29", "\x5D", "\x7D"
          # closing delimiter
          @tokens << tok if tok.size > 0
          @tokens << chr
          tok = ""
          break
        else
          tok << chr
        end
      end

      @tokens << tok if tok.size > 0
    end

    # peek at the next character in the io stream, leaving the stream position
    # untouched
    #
    def peek_char
      chr = @io.read(1)
      @io.seek(-1, IO::SEEK_CUR) unless chr.nil?
      chr
    end
  end
end
