# typed: false
# coding: utf-8

describe PDF::Reader::CidWidths, "#initilize" do
  context "with an empty array" do
    subject { PDF::Reader::CidWidths.new(500, [])}

    it "returns the default width" do
      expect(subject[1]).to eq(500)
    end
  end

  context "with an array using the first form" do
    subject { PDF::Reader::CidWidths.new(500, [1, [10, 20, 30]])}

    it "returns correct width for index 1" do
      expect(subject[1]).to eq(10)
    end

    it "returns correct width for index 2" do
      expect(subject[2]).to eq(20)
    end

    it "returns correct width for index 3" do
      expect(subject[3]).to eq(30)
    end

    it "returns correct width for index 4" do
      expect(subject[4]).to eq(500)
    end
  end

  context "with an array using the second form" do
    subject { PDF::Reader::CidWidths.new(500, [1, 3, 10])}

    it "returns correct width for index 1" do
      expect(subject[1]).to eq(10)
    end

    it "returns correct width for index 2" do
      expect(subject[2]).to eq(10)
    end

    it "returns correct width for index 3" do
      expect(subject[3]).to eq(10)
    end

    it "returns correct width for index 4" do
      expect(subject[4]).to eq(500)
    end
  end

  context "with an array mixing the first and second form" do
    let!(:widths) {
      [
        1, [10, 20, 30],
        4, 6, 40,
      ]
    }
    subject       { PDF::Reader::CidWidths.new(500, widths)}

    it "returns correct width for index 1" do
      expect(subject[1]).to eq(10)
    end

    it "returns correct width for index 2" do
      expect(subject[2]).to eq(20)
    end

    it "returns correct width for index 3" do
      expect(subject[3]).to eq(30)
    end

    it "returns correct width for index 4" do
      expect(subject[4]).to eq(40)
    end

    it "returns correct width for index 5" do
      expect(subject[5]).to eq(40)
    end

    it "returns correct width for index 6" do
      expect(subject[6]).to eq(40)
    end

    it "returns correct width for index 7" do
      expect(subject[7]).to eq(500)
    end
  end

end
