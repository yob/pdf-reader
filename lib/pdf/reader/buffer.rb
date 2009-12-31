# coding: utf-8

class PDF::Reader
  class Buffer

    def initialize (io)
      @io = io
      @tokens = []

      prepare_tokens
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
