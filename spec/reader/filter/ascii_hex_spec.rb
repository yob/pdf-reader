# typed: false
# coding: utf-8

describe PDF::Reader::Filter::AsciiHex do
  describe "#filter" do
    it "filters a ASCIIHex stream correctly" do
      filter = PDF::Reader::Filter::AsciiHex.new
      encoded_data = "<52756279>"
      expect(filter.filter(encoded_data)).to eql("Ruby")
    end

    it "filters a ASCIIHex stream missing delimiters" do
      filter = PDF::Reader::Filter::AsciiHex.new
      encoded_data = "52756279"
      expect(filter.filter(encoded_data)).to eql("Ruby")
    end

    it "filters a ASCIIHex stream with an odd number of nibbles" do
      filter = PDF::Reader::Filter::AsciiHex.new
      encoded_data = "5275627"
      expect(filter.filter(encoded_data)).to eql("Rubp")
    end
  end
end
