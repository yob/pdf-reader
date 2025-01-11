# typed: false
# coding: utf-8

describe PDF::Reader::AdvancedTextRunFilter do
  let(:text_runs) do
    [
      PDF::Reader::TextRun.new(0, 0, 100, 12, "sample text"),
      PDF::Reader::TextRun.new(0, 1, 120, 14, "another text"),
      PDF::Reader::TextRun.new(2, 1, 80, 10, "sample"),
      PDF::Reader::TextRun.new(0, 2, 80, 20, "other")
    ]
  end

  let(:result_text) { result.map(&:text) }

  describe ".only" do
    let(:result) { described_class.only(text_runs, filter_hash) }

    context "when empty conditions are provided" do
      let(:filter_hash) { {} }

      it "returns all text runs" do
        expect(result_text).to eq(["sample text", "another text", "sample", "other"])
      end
    end

    context "when a single condition is provided" do
      let(:filter_hash) { { text: { include: "sample" } } }

      it "returns text runs matching the condition" do
        expect(result_text).to eq(["sample text", "sample"])
      end
    end

    context "when multiple conditions are provided" do
      let(:filter_hash) { { font_size: { greater_than: 10, less_than: 15 } } }

      it "returns text runs matching the conditions" do
        expect(result_text).to eq(["sample text",  "another text"])
      end
    end

    context "when or conditions are provided" do
      let(:filter_hash) { {
        or: [
          { text: { include: "sample" } },
          { width: { greater_than: 100 } }]
      } }

      it "returns text runs matching the conditions" do
        expect(result_text).to eq(["sample text", "another text", "sample"])
      end
    end

    context "when and conditions are provided" do
      let(:filter_hash) { {
        and: [
          { font_size: { greater_than: 10 } },
          { text: { include: "sample" } }]
      } }

      it "returns text runs matching the conditions" do
        expect(result_text).to eq(["sample text"])
      end
    end

    context "when invalid operator is provided" do
      let(:filter_hash) { { text: { invalid_operator: "sample" } } }

      it "raises error" do
        expect { result }.to raise_error(ArgumentError, "Invalid operator: invalid_operator")
      end
    end

    context "OPERATORS" do
      context "equal" do
        let(:filter_hash) { { font_size: { equal: 12 } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["sample text"])
        end
      end

      context "not_equal" do
        let(:filter_hash) { { font_size: { not_equal: 12 } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["another text", "sample", "other"])
        end
      end

      context "greater_than" do
        let(:filter_hash) { { font_size: { greater_than: 12 } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["another text", "other"])
        end
      end

      context "less_than" do
        let(:filter_hash) { { font_size: { less_than: 12 } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["sample"])
        end
      end

      context "greater_than_or_equal" do
        let(:filter_hash) { { font_size: { greater_than_or_equal: 12 } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["sample text", "another text", "other"])
        end
      end

      context "less_than_or_equal" do
        let(:filter_hash) { { font_size: { less_than_or_equal: 12 } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["sample text", "sample"])
        end
      end

      context "include" do
        let(:filter_hash) { { text: { include: "text" } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["sample text", "another text"])
        end
      end

      context "exclude" do
        let(:filter_hash) { { text: { exclude: "text" } } }

        it "returns text runs matching the condition" do
          expect(result_text).to eq(["sample", "other"])
        end
      end
    end
  end

  describe ".exclude" do
    let(:result) { described_class.exclude(text_runs, filter_hash) }

    context "when empty conditions are provided" do
      let(:filter_hash) { {} }

      it "returns all text runs" do
        expect(result_text).to eq(["sample text", "another text", "sample", "other"])
      end
    end

    context "when a single condition is provided" do
      let(:filter_hash) { { text: { include: "sample" } } }

      it "returns text runs not matching the condition" do
        expect(result_text).to eq(["another text", "other"])
      end
    end

    context "when multiple conditions are provided" do
      let(:filter_hash) { { font_size: { greater_than: 10, less_than: 15 } } }

      it "returns text runs not matching the conditions" do
        expect(result_text).to eq(["sample", "other"])
      end
    end

    context "when or conditions are provided" do
      let(:filter_hash) { {
        or: [
          { text: { include: "sample" } },
          { width: { greater_than: 100 } }]
      } }

      it "returns text runs not matching the conditions" do
        expect(result_text).to eq(["other"])
      end
    end

    context "when and conditions are provided" do
      let(:filter_hash) { {
        and: [
          { font_size: { greater_than: 10 } },
          { text: { include: "sample" } }]
      } }

      it "returns text runs not matching the conditions" do
        expect(result_text).to eq(["another text", "sample", "other"])
      end
    end

    context "when invalid operator is provided" do
      let(:filter_hash) { { text: { invalid_operator: "sample" } } }

      it "raises error" do
        expect { result }.to raise_error(ArgumentError, "Invalid operator: invalid_operator")
      end
    end

    context "OPERATORS" do
      context "equal" do
        let(:filter_hash) { { font_size: { equal: 12 } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["another text", "sample", "other"])
        end
      end

      context "not_equal" do
        let(:filter_hash) { { font_size: { not_equal: 12 } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["sample text"])
        end
      end

      context "greater_than" do
        let(:filter_hash) { { font_size: { greater_than: 12 } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["sample text", "sample"])
        end
      end

      context "less_than" do
        let(:filter_hash) { { font_size: { less_than: 12 } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["sample text", "another text", "other"])
        end
      end

      context "greater_than_or_equal" do
        let(:filter_hash) { { font_size: { greater_than_or_equal: 12 } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["sample"])
        end
      end

      context "less_than_or_equal" do
        let(:filter_hash) { { font_size: { less_than_or_equal: 12 } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["another text", "other"])
        end
      end

      context "include" do
        let(:filter_hash) { { text: { include: "text" } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["sample", "other"])
        end
      end

      context "exclude" do
        let(:filter_hash) { { text: { exclude: "text" } } }

        it "returns text runs not matching the condition" do
          expect(result_text).to eq(["sample text", "another text"])
        end
      end
    end
  end
end
