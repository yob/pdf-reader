# typed: false
# coding: utf-8

describe PDF::Reader::OrientationDetector do
  describe "#orientation" do

    context "with a portrait page and no rotation" do
      let!(:detector) {
        PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 612, 792])
      }
      it "returns portrait" do
        expect(detector.orientation).to eq('portrait')
      end
    end

    context "with a portrait page and -90° rotation" do
      let!(:detector) {
        PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 612, 792], :Rotate => 270)
      }
      it "returns landscape" do
        expect(detector.orientation).to eq('landscape')
      end
    end

    context "with a portrait page and 360° rotation" do
      let!(:detector) {
        PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 612, 792], :Rotate => 360)
      }
      it "returns portrait" do
        expect(detector.orientation).to eq('portrait')
      end
    end

    context "with a landscape page and no rotation" do
      let!(:detector) {
        PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 792, 612])
      }
      it "returns landscape" do
        expect(detector.orientation).to eq('landscape')
      end
    end

    context "with a landscape page and 90° rotation" do
      let!(:detector) {
        PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 792, 612], :Rotate => 90)
      }
      it "returns portrait" do
        expect(detector.orientation).to eq('portrait')
      end
    end

    context "with a landscape page and 360° rotation" do
      let!(:detector) {
        PDF::Reader::OrientationDetector.new(:MediaBox => [0, 0, 792, 612], :Rotate => 360)
      }
      it "returns landscape" do
        expect(detector.orientation).to eq('landscape')
      end
    end

    context "with a portrait page that uses negative Y co-ordinates" do
      let!(:detector) {
        PDF::Reader::OrientationDetector.new(:MediaBox => [0,792,612,0])
      }
      it "returns portrait" do
        expect(detector.orientation).to eq('portrait')
      end
    end
  end
end
