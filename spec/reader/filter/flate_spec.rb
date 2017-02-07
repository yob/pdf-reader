# coding: utf-8

describe PDF::Reader::Filter::Flate do
  describe "#filter" do
    it "inflates a RFC1950 (zlib) deflated stream correctly"
    it "inflates a raw RFC1951 deflated stream correctly"

    context "deflated stream with PNG predictors" do
      let(:deflated_path) {
        File.dirname(__FILE__) + "/../../data/deflated_with_predictors.dat"
      }
      let(:depredicted_path) {
        File.dirname(__FILE__) + "/../../data/deflated_with_predictors_result.dat"
      }
      let(:deflated_data) { binread(deflated_path) }
      let(:depredicted_data) { binread(depredicted_path) }

      it "inflates the data" do
        filter = PDF::Reader::Filter::Flate.new(
          :Columns => 5,
          :Predictor => 12
        )
        expect(filter.filter(deflated_data)).to eql(depredicted_data)
      end
    end

    context "deflated stream with tiff predictors" do
      let(:original_data) { "abcabcabcabcabcabcabcabcabcabc" }
      let(:predicted_data)  {
        "abc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00abc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      }

      it "inflates the data" do
        filter = PDF::Reader::Filter::Flate.new(
          :Columns => 5,
          :Predictor => 2,
          :Colors => 3
        )
        deflated_data = Zlib::Deflate.deflate(predicted_data)

        expect(filter.filter(deflated_data)).to eql(original_data)
      end
    end
  end
end
