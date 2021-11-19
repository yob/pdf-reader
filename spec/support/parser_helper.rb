# typed: true
# coding: utf-8

module ParserHelper
  def parse_string(r)
    buf = PDF::Reader::Buffer.new(StringIO.new(r))
    PDF::Reader::Parser.new(buf, nil)
  end
end
