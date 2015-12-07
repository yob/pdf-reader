# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::TextRun, "#initilize" do
  context "when initialized with valid values" do
    let(:x)     { 10 }
    let(:y)     { 20 }
    let(:width) { 30 }
    let(:font)  { 12 }
    let(:text)  { "Chunky" }

    subject { PDF::Reader::TextRun.new(x, y, width, font, text)}

    it "should make x accessible" do
      expect(subject.x).to eq(10)
    end

    it "should make y accessible" do
      expect(subject.y).to eq(20)
    end

    it "should make width accessible" do
      expect(subject.width).to eq(30)
    end

    it "should make font_size accessible" do
      expect(subject.font_size).to eq(12)
    end

    it "should make text accessible" do
      expect(subject.text).to eq("Chunky")
    end
  end
end

describe PDF::Reader::TextRun, "#endx" do
  context "when initialized with valid values" do
    let(:x)     { 10 }
    let(:y)     { 20 }
    let(:width) { 30 }
    let(:font)  { 12 }
    let(:text)  { "Chunky" }

    subject { PDF::Reader::TextRun.new(x, y, width, font, text)}

    it "should equal x + width" do
      expect(subject.endx).to eq(40)
    end
  end
end

describe PDF::Reader::TextRun, "#mergable?" do
  let(:x)     { 10 }
  let(:y)     { 20 }
  let(:width) { 30 }
  let(:font)  { 12 }

  context "the font_sizes match" do
    context "when the two runs are within 1x font_size of each other" do
      let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font, "A")}
      let(:two)   { PDF::Reader::TextRun.new(one.endx+12, y, width, font, "B")}

      it "should return true" do
        expect(one.mergable?(two)).to be_true
      end
    end

    context "when the two runs are over 1x font_size away from each other" do
      let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font, "A")}
      let(:two)   { PDF::Reader::TextRun.new(one.endx+13, y, width, font, "B")}

      it "should return false" do
        expect(one.mergable?(two)).to be_false
      end
    end

    context "when the two runs have identical X values but different Y" do
      let(:one)   { PDF::Reader::TextRun.new(x, y,     width, font, "A")}
      let(:two)   { PDF::Reader::TextRun.new(x, y + 1, width, font, "B")}

      it "should return false" do
        expect(one.mergable?(two)).to be_false
      end
    end
  end
  context "the font_sizes do not match" do
    context "when the two runs are within 1x font_size of each other" do
      let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font,   "A")}
      let(:two)   { PDF::Reader::TextRun.new(one.endx+12, y, width, font+1, "B")}

      it "should return true" do
        expect(one.mergable?(two)).to be_false
      end
    end

    context "when the two runs are over 1x font_size away from each other" do
      let(:one)   { PDF::Reader::TextRun.new(x,           y, width, font,   "A")}
      let(:two)   { PDF::Reader::TextRun.new(one.endx+13, y, width, font+1, "B")}

      it "should return false" do
        expect(one.mergable?(two)).to be_false
      end
    end

    context "when the two runs have identical X values but different Y" do
      let(:one)   { PDF::Reader::TextRun.new(x, y,     width, font,   "A")}
      let(:two)   { PDF::Reader::TextRun.new(x, y + 1, width, font+1, "B")}

      it "should return false" do
        expect(one.mergable?(two)).to be_false
      end
    end
  end
end

describe PDF::Reader::TextRun, "#+" do
  let(:x)     { 10 }
  let(:y)     { 20 }
  let(:width) { 30 }
  let(:font)  { 12 }

  context "when the two runs are 0.12x font_size of each other" do
    let(:one)   { PDF::Reader::TextRun.new(x,            y, width, font, "A")}
    let(:two)   { PDF::Reader::TextRun.new(one.endx+1.2, y, width, font, "B")}

    it "should return a new TextRun with combined data" do
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

    it "should return a new TextRun with combined data" do
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

    it "should raise an exception" do
      expect {
        one + two
      }.to raise_error(ArgumentError)
    end
  end
end

describe PDF::Reader::TextRun, "#<=>" do
  let(:width) { 30 }
  let(:font)  { 12 }
  let(:text)  { "Chunky" }

  context "when comparing two runs in the same position" do
    let!(:one) { PDF::Reader::TextRun.new(10, 20, width, font, text)}
    let!(:two) { PDF::Reader::TextRun.new(10, 20, width, font, text)}

    it "should return 0" do
      expect(one <=> two).to eq(0)
    end
  end

  context "when run two is directly above run one" do
    let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
    let!(:two) { PDF::Reader::TextRun.new(10, 20, width, font, text)}

    it "should sort two before one" do
      expect([one, two].sort).to eq([two, one])
    end
  end

  context "when run two is directly right of run one" do
    let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
    let!(:two) { PDF::Reader::TextRun.new(20, 10, width, font, text)}

    it "should sort one before two" do
      expect([one, two].sort).to eq([one, two])
    end
  end

  context "when run two is directly below run one" do
    let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
    let!(:two) { PDF::Reader::TextRun.new(10, 05, width, font, text)}

    it "should sort one before two" do
      expect([one, two].sort).to eq([one, two])
    end
  end

  context "when run two is directly left of run one" do
    let!(:one) { PDF::Reader::TextRun.new(10, 10, width, font, text)}
    let!(:two) { PDF::Reader::TextRun.new(5, 10, width, font, text)}

    it "should sort two before one" do
      expect([one, two].sort).to eq([two, one])
    end
  end

end

describe PDF::Reader::TextRun, "#mean_character_width" do
  let(:width) { 30 }
  let(:font)  { 12 }
  let(:text)  { "Chunky" }

  context "when the run is 30pts wide with 6 characters" do
    subject { PDF::Reader::TextRun.new(10, 20, width, font, text)}

    it "should return 5.0" do
      expect(subject.mean_character_width).to eq(5.0)
    end
  end
end
