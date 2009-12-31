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

    def pop
      prepare_tokens if @tokens.empty?

      @tokens.shift
    end

    private

    def prepare_tokens
      10.times { prepare_token }
    end

    def prepare_token
      tok = ""

      while chr = @io.read(1)
        case chr
          # do nothing
        when "\x00", "\x09", "\x0A", "\x0C", "\x0D", "\x20"
          # white space, token finished
          @tokens << tok if tok.size > 0
          tok = ""
        when "\x28", "\x3C", "\x5B", "\x7B", "\x2F", "\x25"
          # opening delimiter, start of new token
          @tokens << tok if tok.size > 0
          tok = chr
        when "\x29", "\x3E", "\x5D", "\x7D"
          # closing delimiter
          tok << chr
          @tokens << tok
          tok = ""
        else
          tok << chr
        end
      end

      @tokens << tok if tok.size > 0
    end
  end
end
