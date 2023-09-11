# coding: ASCII-8BIT
# frozen_string_literal: true

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

require 'strscan'

class PDF::Reader

  # A string tokeniser that recognises PDF grammar. When passed an IO stream or a
  # string, repeated calls to token() will return the next token from the source.
  #
  # This is very low level, and getting the raw tokens is not very useful in itself.
  #
  # This will usually be used in conjunction with PDF:Reader::Parser, which converts
  # the raw tokens into objects we can work with (strings, ints, arrays, etc)
  #
  class BufferNew
    #TOKEN_WHITESPACE=[0x00, 0x09, 0x0A, 0x0C, 0x0D, 0x20]
    #TOKEN_DELIMITER=[0x25, 0x3C, 0x3E, 0x28, 0x5B, 0x7B, 0x29, 0x5D, 0x7D, 0x2F]
    TOKEN_ALPHA = /[a-zA-Z0-9\-\.]+/
    TOKEN_DELIMITER = /[\u{5b}\u{5d}]/ # [ ]
    TOKEN_NUM = /\d+(\.\d+)?/
    TOKEN_WHITESPACE = /\s+/
    TOKEN_OPEN_HASH = /\u{3c}{2}/
    TOKEN_CLOSE_HASH = /\u{3e}{2}/
    TOKEN_OPEN_HEXSTRING = /\u{3c}/
    TOKEN_CLOSE_HEXSTRING = /\u{3e}/
    TOKEN_OPEN_LITSTRING = /\u{28}/
    TOKEN_CLOSE_LITSTRING = /\u{29}/
    TOKEN_OPEN_NAME = /\u{2f}/
    TOKEN_COMMENT = /\u{25}.*$/ # % to end of line
    TOKEN_INDIRECT_OBJECT = /\d+\s\d+\sR/

    TOKEN_INSIDE_LITSTRING = /[^\)]+/m
    TOKEN_INSIDE_HEXSTRING = /[^\>]+/m

    CR = "\r"
    LF = "\n"
    CRLF = "\r\n"

    # Quite a few PDFs have trailing junk.
    # This can be several k of nuls in some cases
    # Allow for this here
    TRAILING_BYTECOUNT = 5000

    # Creates a new buffer.
    #
    # Params:
    #
    #   io - an IO stream (usually a StringIO) with the raw data to tokenise
    #
    # options:
    #
    #   :seek - a byte offset to seek to before starting to tokenise
    #   :content_stream - set to true if buffer will be tokenising a
    #                     content stream. Defaults to false
    #
    def initialize(io, opts = {})
      @io = io
      @scan = StringScanner.new(@io.string)
      if opts[:seek]
        @scan.pos = opts[:seek]
      end
      @mode = :regular
      @tokens = []
    end

    def pos
      @scan.pos
    end

    # return true if there are no more tokens left
    #
    def empty?
      prepare_three_tokens if @tokens.size < 3

      @tokens.empty?
    end

    # return raw bytes from the underlying IO stream.
    #
    #   bytes - the number of bytes to read
    #
    # options:
    #
    #   :skip_eol - if true, the IO stream is advanced past a CRLF, CR or LF
    #               that is sitting under the io cursor.
    #   Note:
    #   Skipping a bare CR is not spec-compliant.
    #   This is because the data may start with LF.
    #   However we check for CRLF first, so the ambiguity is avoided.
    def read(bytes, opts = {})
      #reset_pos

      if opts[:skip_eol]
        str = @scan.peek(2)
        require 'pry'
        binding.pry
        if str.nil?
          return nil
        elsif str == CRLF # This MUST be done before checking for CR alone
          # do nothing
        elsif str[0, 1] == LF || str[0, 1] == CR # LF or CR alone
          @scan.pos = @scan.pos + 1
        else
          # do nothing
          #@io.seek(-2, IO::SEEK_CUR)
          #@scan.pos = @scan.pos - 1
        end
      end
      @io.seek(@scan.pos)

      bytes = @io.read(bytes)
      @scan.pos = @io.pos
      bytes
    end

    def token
      prepare_three_tokens if @tokens.size < 3 && @tokens.last != "stream"

      @tokens.shift
    end

    # return the byte offset where the first XRef table in th source can be found.
    #
    def find_first_xref_offset
      check_size_is_non_zero
      @io.seek(-TRAILING_BYTECOUNT, IO::SEEK_END) rescue @io.seek(0)
      data = @io.read(TRAILING_BYTECOUNT)

      raise MalformedPDFError, "PDF does not contain EOF marker" if data.nil?

      # the PDF 1.7 spec (section #3.4) says that EOL markers can be either \r, \n, or both.
      lines = data.split(/[\n\r]+/).reverse
      eof_index = lines.index { |l| l.strip[/^%%EOF/] }

      raise MalformedPDFError, "PDF does not contain EOF marker" if eof_index.nil?
      raise MalformedPDFError, "PDF EOF marker does not follow offset" if eof_index >= lines.size-1
      offset = lines[eof_index+1].to_i

      # a byte offset < 0 doesn't make much sense. This is unlikely to happen, but in theory some
      # corrupted PDFs might have a line that looks like a negative int preceding the `%%EOF`
      raise MalformedPDFError, "invalid xref offset" if offset < 0
      offset
    end

    private

    def check_size_is_non_zero
      @io.seek(-1, IO::SEEK_END)
      @io.seek(0)
    rescue Errno::EINVAL
      raise MalformedPDFError, "PDF file is empty"
    end

    def prepare_three_tokens
      3.times { prepare_tokens }
    end

    def prepare_tokens
      if @scan.eos?
        if @mode == :literal_string
          @mode = :regular
          @tokens << ")"
        end
        return
      end

      case @mode
      when :regular
        case
        when s = @scan.scan(TOKEN_INDIRECT_OBJECT)  then
          _, id, gen = *s.match(/(\d+)\s(\d+)\sR/)
          @tokens << PDF::Reader::Reference.new(id.to_i, gen.to_i)
        when s = @scan.scan(TOKEN_ALPHA) then
          @tokens << s
        when s = @scan.scan(TOKEN_NUM)  then
          @tokens << s
        when s = @scan.scan(TOKEN_DELIMITER) then
          @tokens << s
        when s = @scan.scan(TOKEN_COMMENT)  then
          # nothing
        when s = @scan.scan(TOKEN_OPEN_HASH)  then
          @tokens << s
        when s = @scan.scan(TOKEN_CLOSE_HASH)  then
          @tokens << s
        when s = @scan.scan(TOKEN_OPEN_HEXSTRING)  then
          @mode = :hex_string
          @tokens << s
        when s = @scan.scan(TOKEN_CLOSE_HEXSTRING)  then
          @tokens << s
        when s = @scan.scan(TOKEN_OPEN_LITSTRING)  then
          @mode = :literal_string
          @tokens << s
        when s = @scan.scan(TOKEN_CLOSE_LITSTRING) then
          @tokens << s
        when s = @scan.scan(TOKEN_OPEN_NAME)  then
          @tokens << s
        when s = @scan.scan(TOKEN_WHITESPACE)  then
          # nothing
        else
          puts @scan.inspect
          raise "oh no"
        end
      when :literal_string then
        s = @scan.scan(TOKEN_INSIDE_LITSTRING)
        if s
          @tokens << s
        end
        @mode = :regular
      when :hex_string then
        s = @scan.scan(TOKEN_INSIDE_HEXSTRING)
        if s
          s.gsub!(/[^0-9a-fA-F]/,"")
          @tokens << s
        end
        @mode = :regular
      end
    end
  end
end
