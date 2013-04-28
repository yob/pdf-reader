# coding: utf-8

module ParserHelper
  def parse_string(r)
    buf = Marron::Buffer.new(StringIO.new(r))
    Marron::Parser.new(buf, nil)
  end
end
