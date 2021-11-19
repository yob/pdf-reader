# typed: false
# coding: utf-8

describe PDF::Reader::Filter::Ascii85 do
  describe "#filter" do
    it "filters a ASCII85 stream correctly" do
      filter = PDF::Reader::Filter::Ascii85.new
      encoded_data = Ascii85::encode("Ruby")
      expect(filter.filter(encoded_data)).to eql("Ruby")
    end

    it "filters a ASCII85 stream missing <~ correctly" do
      filter = PDF::Reader::Filter::Ascii85.new
      encoded_data = Ascii85::encode("Ruby")[2,100]
      expect(filter.filter(encoded_data)).to eql("Ruby")
    end
  end
end
