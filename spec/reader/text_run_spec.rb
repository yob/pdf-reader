# typed: false
# coding: utf-8

describe PDF::Reader::TextRun do
  describe "#initilize" do
    context "when initialized with valid values" do
      let(:x)     { 10 }
      let(:y)     { 20 }
      let(:width) { 30 }
      let(:font)  { 12 }
      let(:text)  { "Chunky" }

      subject { PDF::Reader::TextRun.new(x, y, width, font, text)}

      it "makes x accessible" do
        expect(subject.x).to eq(10)
      end

      it "makes y accessible" do
        expect(subject.y).to eq(20)
      end

      it "makes width accessible" do
        expect(subject.width).to eq(30)
      end

      it "makes font_size accessible" do
        expect(subject.font_size).to eq(12)
      end

      it "makes text accessible" do
        expect(subject.text).to eq("Chunky")
      end
    end
  end

  describe "#endx" do
    context "when initialized with valid values" do
      let(:x)     { 10 }
      let(:y)     { 20 }
      let(:width) { 30 }
      let(:font)  { 12 }
      let(:text)  { "Chunky" }

      subject { PDF::Reader::TextRun.new(x, y, width, font, text)}

      it "equals x + width" do
        expect(subject.endx).to eq(40)
      end
    end
  end

  describe "#mergable?" do
    let(:x)     { 10 }
    let(:y)     { 20 }
    let(:width) { 30 }
    let(:font)  { 12 }

    context "the font_sizes match" do
      context "when the two runs are within 1x font_size of each other" do
        let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font, "A")}
        let(:two)   { PDF::Reader::TextRun.new(one.endx+12, y, width, font, "B")}

        it "returns true" do
          expect(one.mergable?(two)).to be_truthy
        end
      end

      context "when the two runs are over 1x font_size away from each other" do
        let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font, "A")}
        let(:two)   { PDF::Reader::TextRun.new(one.endx+13, y, width, font, "B")}

        it "returns false" do
          expect(one.mergable?(two)).to be_falsey
        end
      end

      context "when the two runs have identical X values but different Y" do
        let(:one)   { PDF::Reader::TextRun.new(x, y,     width, font, "A")}
        let(:two)   { PDF::Reader::TextRun.new(x, y + 1, width, font, "B")}

        it "returns false" do
          expect(one.mergable?(two)).to be_falsey
        end
      end
    end
    context "the font_sizes do not match" do
      context "when the two runs are within 1x font_size of each other" do
        let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font,   "A")}
        let(:two)   { PDF::Reader::TextRun.new(one.endx+12, y, width, font+1, "B")}

        it "returns true" do
          expect(one.mergable?(two)).to be_falsey
        end
      end

      context "when the two runs are over 1x font_size away from each other" do
        let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font,   "A")}
        let(:two)   { PDF::Reader::TextRun.new(one.endx+13, y, width, font+1, "B")}

        it "returns false" do
          expect(one.mergable?(two)).to be_falsey
        end
      end

      context "when the two runs have identical X values but different Y" do
        let(:one)   { PDF::Reader::TextRun.new(x, y,     width, font,   "A")}
        let(:two)   { PDF::Reader::TextRun.new(x, y + 1, width, font+1, "B")}

        it "returns false" do
          expect(one.mergable?(two)).to be_falsey
        end
      end
    end
  end

  describe "#+" do
    let(:x)     { 10 }
    let(:y)     { 20 }
    let(:width) { 30 }
    let(:font)  { 12 }

    context "when the two runs are 0.12x font_size of each other" do
      let(:one)   { PDF::Reader::TextRun.new(x,            y, width, font, "A")}
      let(:two)   { PDF::Reader::TextRun.new(one.endx+1.2, y, width, font, "B")}

      it "returns a new TextRun with combined data" do
        result = one + two
        expect(result.x).to     eq(10)
        expect(result.y).to     eq(20)
        expect(result.width).to eq(61.2)
        expect(result.text).to  eq("AB")
      end
    end

    context "when the two runs are 1x font_size of each other" do
      let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font, "A")}
      let(:two)   { PDF::Reader::TextRun.new(one.endx+12, y, width, font, "B")}

      it "returns a new TextRun with combined data" do
        result = one + two
        expect(result.x).to     eq(10)
        expect(result.y).to     eq(20)
        expect(result.width).to eq(72)
        expect(result.text).to  eq("A B")
      end
    end

    context "when the two runs are over 12pts away from each other" do
      let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font, "A")}
      let(:two)   { PDF::Reader::TextRun.new(one.endx+13, y, width, font, "B")}

      it "raises an exception" do
        expect {
          one + two
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#<=>" do
    let(:width) { 30 }
    let(:font)  { 12 }
    let(:text)  { "Chunky" }

    context "when comparing two runs in the same position" do
      let!(:one) { PDF::Reader::TextRun.new(10, 20, width, font, text)}
      let!(:two) { PDF::Reader::TextRun.new(10, 20, width, font, text)}

      it "returns 0" do
        expect(one <=> two).to eq(0)
      end
    end

    context "when run two is directly above run one" do
      let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
      let!(:two) { PDF::Reader::TextRun.new(10, 20, width, font, text)}

      it "sorts two before one" do
        expect([one, two].sort).to eq([two, one])
      end
    end

    context "when run two is directly right of run one" do
      let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
      let!(:two) { PDF::Reader::TextRun.new(20, 10, width, font, text)}

      it "sorts one before two" do
        expect([one, two].sort).to eq([one, two])
      end
    end

    context "when run two is directly below run one" do
      let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
      let!(:two) { PDF::Reader::TextRun.new(10, 05, width, font, text)}

      it "sorts one before two" do
        expect([one, two].sort).to eq([one, two])
      end
    end

    context "when run two is directly left of run one" do
      let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
      let!(:two) { PDF::Reader::TextRun.new(5, 10, width, font, text)}

      it "sorts two before one" do
        expect([one, two].sort).to eq([two, one])
      end
    end

  end

  describe "#mean_character_width" do
    let(:width) { 30 }
    let(:font)  { 12 }
    let(:text)  { "Chunky" }

    context "when the run is 30pts wide with 6 characters" do
      subject { PDF::Reader::TextRun.new(10, 20, width, font, text)}

      it "returns 5.0" do
        expect(subject.mean_character_width).to eq(5.0)
      end
    end
  end

  describe "#intersect" do
    let(:result) {
      run_one.intersect?(run_two)
    }

    context "with two runs that don't intersect" do
      let(:run_one) { PDF::Reader::TextRun.new(30, 700, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(100, 500, 10, 12, "H") }

      it "returns false" do
        expect(result).to eq(false)
      end
    end

    context "when run_two overlaps the top of run_one" do
      let(:run_one) { PDF::Reader::TextRun.new(30, 100, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(30, 110, 10, 12, "H") }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "when run_two overlaps the bottom of run_one" do
      let(:run_one) { PDF::Reader::TextRun.new(30, 100, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(30, 92, 10, 12, "H") }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "when run_two overlaps the left of run_one" do
      let(:run_one) { PDF::Reader::TextRun.new(30, 100, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(25, 100, 10, 12, "H") }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "when run_two overlaps the right of run_one" do
      let(:run_one) { PDF::Reader::TextRun.new(30, 100, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(35, 100, 10, 12, "H") }

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "with two identical runs" do
      let(:run_one) { PDF::Reader::TextRun.new(30, 700, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(30, 700, 10, 12, "H") }

      it "returns true" do
        expect(result).to eq(true)
      end
    end
  end

  describe "#intersection_area_percent" do
    let(:result) {
      run_one.intersection_area_percent(run_two)
    }

    context "with two runs that don't intersect" do
      let(:run_one) { PDF::Reader::TextRun.new(30, 700, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(100, 500, 10, 12, "H") }

      it "returns 0" do
        expect(result).to eq(0)
      end
    end

    context "when run_two overalps with 50% of run_one" do
      let(:run_one) { PDF::Reader::TextRun.new(100, 100, 10, 12, "H") }
      let(:run_two) { PDF::Reader::TextRun.new(105, 100, 10, 12, "H") }

      it "returns 0.5" do
        expect(result).to be_within(0.01).of(0.5)
      end
    end
  end
end
