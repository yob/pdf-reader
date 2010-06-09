# coding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'
require 'timeout'

module BufferHelper
  def parse_string (r)
    PDF::Reader::Buffer.new(StringIO.new(r))
  end
end

module ParserHelper
  def parse_string (r)
    buf = PDF::Reader::Buffer.new(StringIO.new(r))
    PDF::Reader::Parser.new(buf, nil)
  end
end
