# coding: ASCII-8BIT
# frozen_string_literal: true

class PDF::Reader

  class BufferNew
    #TOKEN_WHITESPACE=[0x00, 0x09, 0x0A, 0x0C, 0x0D, 0x20]
    #TOKEN_DELIMITER=[0x25, 0x3C, 0x3E, 0x28, 0x5B, 0x7B, 0x29, 0x5D, 0x7D, 0x2F]
    TOKEN_ALPHA = /[a-zA-Z0-9\%]+/
    TOKEN_NUM = /\d+(\.\d+)?/
    TOKEN_WHITESPACE = /\s+/
    TOKEN_OPEN_HASH = /\u{3c}{2}/
    TOKEN_CLOSE_HASH = /\u{3e}{2}/
    TOKEN_OPEN_HEXSTRING = /\u{3c}/
    TOKEN_CLOSE_HEXSTRING = /\u{3e}/
    TOKEN_OPEN_LITSTRING = /\u{28}/
    TOKEN_CLOSE_LITSTRING = /\u{29}/
    TOKEN_OPEN_NAME = /\u{2f}/

    def initialize(io, opts = {})
      @io = io
      @scan = StringScanner.new(@io.string)
    end

    def token
      return if @scan.eos?

      case
      when s = @scan.scan(TOKEN_ALPHA)  then s
      when s = @scan.scan(TOKEN_NUM)  then s
      when s = @scan.scan(TOKEN_OPEN_HASH)  then s
      when s = @scan.scan(TOKEN_CLOSE_HASH)  then s
      when s = @scan.scan(TOKEN_OPEN_HEXSTRING)  then s
      when s = @scan.scan(TOKEN_CLOSE_HEXSTRING)  then s
      when s = @scan.scan(TOKEN_OPEN_LITSTRING)  then s
      when s = @scan.scan(TOKEN_CLOSE_LITSTRING)  then s
      when s = @scan.scan(TOKEN_OPEN_NAME)  then s
      when s = @scan.scan(TOKEN_WHITESPACE)  then token
      else
        puts @scan.inspect
        raise "oh no"
      end
    end
  end
end
