# coding: utf-8

describe PDF::Reader::Filter::Flate do
  describe "#filter" do
    it "inflates a RFC1950 (zlib) deflated stream correctly"
    it "inflates a raw RFC1951 deflated stream correctly"
    it "inflates a deflated stream with PNG predictors correctly" do
      filter = PDF::Reader::Filter::Flate.new(:Columns => 5, :Predictor => 12)
      deflated_data    = binread(File.dirname(__FILE__) + "/../../data/deflated_with_predictors.dat")
      depredicted_data = binread(File.dirname(__FILE__) + "/../../data/deflated_with_predictors_result.dat")
      expect(filter.filter(deflated_data)).to eql(depredicted_data)
    end

    it "inflates a deflated stream with tiff predictors correctly" do
      filter         = PDF::Reader::Filter::Flate.new(:Columns => 5, :Predictor => 2, :Colors => 3)
      original_data  = "abcabcabcabcabcabcabcabcabcabc"
      predicted_data = "abc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00abc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      deflated_data  = Zlib::Deflate.deflate(predicted_data)

      expect(filter.filter(deflated_data)).to eql(original_data)
    end
  end
end
