# typed: false
# coding: utf-8

describe PDF::Reader::Filter::RunLength do
  describe "#filter" do
    it "filters a RunLengthDecode stream correctly" do
      filter = PDF::Reader::Filter::RunLength.new
      encoded_data = [2, "\x00"*3, 255, "\x01", 128].pack('Ca*Ca*C')
      expect(filter.filter(encoded_data)).to eql("\x00\x00\x00\x01\x01")
    end
  end
end
