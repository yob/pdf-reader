# typed: false
# coding: utf-8

describe PDF::Reader::OverlappingRunsFilter, "#exclude_redundant_runs" do

  let(:result) {
    PDF::Reader::OverlappingRunsFilter.exclude_redundant_runs(runs)
  }

  context "when there's a single run" do
    let(:runs) do
      [
        PDF::Reader::TextRun.new(30, 700, 50, 12, "")
      ]
    end

    it "returns the run unmodified" do
      expect(result).to match_array(runs)
    end
  end

  context "when there's two non-overlapping runs" do
    let(:runs) do
      [
        PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
        PDF::Reader::TextRun.new(30, 676, 50, 12, "World"),
      ]
    end

    it "returns the run unmodified" do
      expect(result).to match_array(runs)
    end
  end

  context "when there's two identical runs" do
    let(:runs) do
      [
        PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
        PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
      ]
    end

    it "returns only one of the runs" do
      expect(result).to match_array(runs.slice(0,1))
    end
  end

  context "when the second run overlaps the right edge of the first" do
    context "by 50%" do
      let(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(55, 700, 50, 12, "Hello"),
        ]
      end
      it "returns only one of the runs" do
        expect(result).to match_array(runs.slice(0,1))
      end
    end
    context "by less than 50%" do
      let(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(65, 700, 50, 12, "Hello"),
        ]
      end
      it "returns only one of the runs" do
        expect(result).to match_array(runs)
      end
    end
  end

  context "when the second run overlaps the left edge of the first" do
    context "by 50%" do
      let(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(5, 700, 50, 12, "Hello"),
        ]
      end
      it "returns only one of the runs" do
        expect(result).to match_array(runs.slice(1,1))
      end
    end
  end

  context "when the second run overlaps the top edge of the first" do
    context "by 50%" do
      let(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(30, 706, 50, 12, "Hello"),
        ]
      end
      it "returns only one of the runs" do
        expect(result).to match_array(runs.slice(0,1))
      end
    end
  end

  context "when the second run overlaps the bottom edge of the first" do
    context "by 50%" do
      let(:runs) do
        [
          PDF::Reader::TextRun.new(30, 700, 50, 12, "Hello"),
          PDF::Reader::TextRun.new(30, 694, 50, 12, "Hello"),
        ]
      end
      it "returns only one of the runs" do
        expect(result).to match_array(runs.slice(0,1))
      end
    end
  end
end
