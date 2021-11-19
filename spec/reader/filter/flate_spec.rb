# typed: false
# coding: utf-8

describe PDF::Reader::Filter::Flate do
  describe "#filter" do
    context "an RFC1950 (zlib) deflated stream" do
      let(:deflated_path) {
        File.dirname(__FILE__) + "/../../data/hello-world.z"
      }
      let(:deflated_data) { binread(deflated_path) }
      it "inflates correctly" do
        filter = PDF::Reader::Filter::Flate.new
        expect(filter.filter(deflated_data)).to eql("hello world, 2020 is quite the year")
      end
    end

    context "an RFC1950 (zlib) deflated stream with an extra byte on the end" do
      let(:deflated_path) {
        File.dirname(__FILE__) + "/../../data/stream-with-extra-byte.z"
      }
      let(:deflated_data) { binread(deflated_path) }
      it "inflates correctly" do
        filter = PDF::Reader::Filter::Flate.new
        result = filter.filter(deflated_data)
        expect(result).to start_with("q")
        expect(result).to end_with("ET\n")
      end
    end

    context "a raw RFC1951 deflated stream" do
      let(:deflated_path) {
        File.dirname(__FILE__) + "/../../data/hello-world.deflate"
      }
      let(:deflated_data) { binread(deflated_path) }
      it "inflates correctly" do
        filter = PDF::Reader::Filter::Flate.new
        expect(filter.filter(deflated_data)).to eql("hello world, 2020 is quite the year")
      end
    end

    # I'm not sure this is strictly required by the PDF spec, but zlib can do it and no doubt
    # someone, somewhere has accidentally made a PDF using gzip
    context "an RFC1952 (gzip) deflated stream" do
      let(:deflated_path) {
        File.dirname(__FILE__) + "/../../data/hello-world.gz"
      }
      let(:deflated_data) { binread(deflated_path) }
      it "inflates correctly" do
        filter = PDF::Reader::Filter::Flate.new
        expect(filter.filter(deflated_data)).to eql("hello world, 2020 is quite the year")
      end
    end

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
