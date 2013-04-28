# coding: utf-8

module BufferHelper
  def parse_string(r)
    Marron::Buffer.new(StringIO.new(r))
  end
end
