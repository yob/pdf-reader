# typed: true
# coding: utf-8

module BufferHelper
  def parse_string(r)
    PDF::Reader::Buffer.new(StringIO.new(r))
  end

  def parse_string2(r)
    PDF::Reader::BufferNew.new(StringIO.new(r))
  end
end
