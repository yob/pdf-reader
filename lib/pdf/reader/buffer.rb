# coding: utf-8

class PDF::Reader
  class Buffer

    attr_reader :pos

    def initialize (io, opts = {})
      @io = io
      @tokens = []
      @options = opts

      @io.seek(opts[:seek]) if opts[:seek]
      @pos = @io.pos
    end

    def empty?
      prepare_tokens if @tokens.size < 3

      @tokens.empty?
    end

    # return raw bytes from the underlying IO stream.
    #
    # If :skip_eol option is true, the IO stream is advanced past any LF or CR
    # bytes before it reads any data. This is to handle content streams, which
    # have a CRLF or LF after the stream token.
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


    def token
      reset_pos
      prepare_tokens if @tokens.size < 3
      merge_indirect_reference
      merge_tokens

      @tokens.shift
    end

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

    def reset_pos
      if @io.pos != @pos
        @io.seek(@pos)
      end
    end

    def save_pos
      @pos = @io.pos
    end

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
