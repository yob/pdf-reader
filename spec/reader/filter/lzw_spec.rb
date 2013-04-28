# coding: utf-8

require "spec_helper"

describe Marron::Filter::Lzw do
  it "should filter a lzw stream with no predictors correctly" do
    filter = Marron::Filter::Lzw.new
    compressed_data   = binread(File.dirname(__FILE__) + "/../../data/lzw_compressed.dat")
    decompressed_data = binread(File.dirname(__FILE__) + "/../../data/lzw_decompressed.dat")
    filter.filter(compressed_data).should eql(decompressed_data)
  end

end
