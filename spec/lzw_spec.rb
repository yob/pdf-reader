# typed: false
# coding: utf-8

describe PDF::Reader::LZW do
  describe "#decode" do
    it "decodes a lzw compress string" do
      content = %w{ 80 0B 60 50 22 0C 0C 85 01 }.map { |byte|
        byte.to_i(16)
      }.pack("C*")

      expect(PDF::Reader::LZW.decode(content)).to eq('-----A---B')
    end

    it "decodes another lzw compressed string" do
      content = binread(File.dirname(__FILE__) + "/data/lzw_compressed2.dat")

      expect(PDF::Reader::LZW.decode(content)).to match(/\ABT/)
    end
  end
end
