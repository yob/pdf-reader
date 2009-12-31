# coding: utf-8

class PDF::Reader
  class Buffer

    def initialize (io)
      @io = io
      @tokens = []
    end

    def empty?
      prepare_tokens if @tokens.empty?

      @tokens.empty?
    end

    def token
      prepare_tokens if @tokens.empty?

      @tokens.shift
    end

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

    private

    def prepare_tokens
      10.times { prepare_token }
      merge_tokens
    end

    def merge_tokens
      @tokens.each_with_index do |tok, idx|
        if tok == "<" && @tokens[idx+1] == "<"
          @tokens.inspect
          @tokens[idx] = "<<"
          @tokens[idx+1] = nil
        elsif tok == ">" && @tokens[idx+1] == ">"
          @tokens[idx] = ">>"
          @tokens[idx+1] = nil
        end
      end
      @tokens.compact!
    end

    def prepare_token
      tok = ""

      while chr = @io.read(1)
        case chr
        when "\x00", "\x09", "\x0A", "\x0C", "\x0D", "\x20"
          # white space, token finished
          @tokens << tok if tok.size > 0
          tok = ""
        when "\x28", "\x3C", "\x5B", "\x7B", "\x2F", "\x25"
          # opening delimiter, start of new token
          @tokens << tok if tok.size > 0
          @tokens << chr
          tok = ""
        when "\x29", "\x3E", "\x5D", "\x7D"
          # closing delimiter
          @tokens << tok if tok.size > 0
          @tokens << chr
          tok = ""
        else
          tok << chr
        end
      end

      @tokens << tok if tok.size > 0
    end
  end
end
