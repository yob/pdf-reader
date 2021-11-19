# typed: false
# coding: utf-8

describe PDF::Reader::Filter::Lzw do
  describe "#filter" do
    it "filters a lzw stream with no predictors correctly" do
      filter = PDF::Reader::Filter::Lzw.new
      compressed_data   = binread(File.dirname(__FILE__) + "/../../data/lzw_compressed.dat")
      decompressed_data = binread(File.dirname(__FILE__) + "/../../data/lzw_decompressed.dat")
      expect(filter.filter(compressed_data)).to eql(decompressed_data)
    end
  end
end
