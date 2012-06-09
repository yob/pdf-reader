# coding: utf-8


require 'pdf/reader'
require 'benchmark'
require 'stringio'

Benchmark.bm(7) do |x|
  x.report("Parser") do
    1000.times do
      buf = PDF::Reader::Buffer.new(StringIO.new("1 q Q"))
      PDF::Reader::Parser.new(buf).parse_token
    end
  end
  x.report("NewParser") do
    1000.times do
      parser = PDF::Reader::NewParser.new("1 q Q")
      #parser.next_token
      parser.all_tokens
    end
  end
end
