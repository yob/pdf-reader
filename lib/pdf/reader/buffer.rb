# coding: utf-8

class PDF::Reader
  class Buffer

    def initialize (io, opts = {})
      @io = io
      @tokens = []
      @options = opts

      @io.seek(opts[:seek]) if opts[:seek]
    end

    def empty?
      prepare_tokens if @tokens.size < 3

      @tokens.empty?
    end

    def read(bytes)
      @io.read(bytes)
    end

    def token
      prepare_tokens if @tokens.size < 3
      merge_indirect_reference
      merge_tokens

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
      10.times do
        if state == :literal_string
          prepare_literal_token
        elsif state == :regular
          prepare_regular_token
        end
      end
    end

    def state
      if @tokens[-1] == "("
        :literal_string
      elsif @tokens[-1] == "stream"
        :stream
      else
        :regular
      end
    end

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

    def prepare_literal_token
      str = ""
      count = 1

      while count > 0
        chr = @io.read(1)
        if chr.nil?
          count = 0 # unbalanced params
        end

        case chr
        when "("
          str << "("
          count += 1
        when ")"
          count -= 1
          str << ")" unless count == 0
        else
          str << chr unless count == 0
        end
      end

      @tokens << str if str.size > 0
      @tokens << ")"
    end


    def prepare_regular_token
      tok = ""

      while chr = @io.read(1)
        case chr
        when "\x00", "\x09", "\x0A", "\x0C", "\x0D", "\x20"
          # white space, token finished
          @tokens << tok if tok.size > 0
          tok = ""
          break
        when "\x28", "\x3C", "\x5B", "\x7B", "\x2F", "\x25"
          # opening delimiter, start of new token
          @tokens << tok if tok.size > 0
          @tokens << chr
          tok = ""
          break
        when "\x29", "\x3E", "\x5D", "\x7D"
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
  end
end
