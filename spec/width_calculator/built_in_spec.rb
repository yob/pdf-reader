# typed: false
# coding: utf-8

describe PDF::Reader::WidthCalculator::BuiltIn do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:font) { double(:basefont => :Helvetica) }
    subject     { PDF::Reader::WidthCalculator::BuiltIn.new(font)}
  end

  describe "#glyph_width" do
    context "With Helvetica, StandardEncoding and no Widths" do
      let!(:encoding)     { PDF::Reader::Encoding.new(:StandardEncoding) }
      let!(:font)         { double(:basefont => :Helvetica,
                                  :subtype => :TrueType,
                                  :encoding => encoding,
                                  :widths => []) }

      let(:width_calculator) {
        PDF::Reader::WidthCalculator::BuiltIn.new(font)
      }

      it "returns width 0 for code point 160(non breaking space)" do
        expect(width_calculator.glyph_width(160)).to eq(0)
      end

      it "returns width 0 for code point 157(unknown)" do
        expect(width_calculator.glyph_width(157)).to eq(0)
      end
    end

    context "With Helvetica and a custom encoding that overwrites standard codepoints" do
      # Codepoint 196 (tilde) is mapped to German umlaut Ä
      let(:encoding)     { PDF::Reader::Encoding.new({:Differences => [196, :Adieresis]}) }
      let(:font)         { double(:basefont => :Helvetica,
                                  :subtype => :Type1,
                                  :encoding => encoding) }

      let(:width_calculator) {
        PDF::Reader::WidthCalculator::BuiltIn.new(font)
      }

      it "returns the correct width for the overwritten codepoint" do
        # tilde = 333, Ä = 667
        expect(width_calculator.glyph_width(196)).to eq(667)
      end
    end

    context "With Foo, a font that isn't part of the built-in 14" do
      let!(:encoding)     { PDF::Reader::Encoding.new(:WinAnsiEncoding) }
      let!(:font)         { double(:basefont => :Foo,
                                  :subtype => :Type1,
                                  :encoding => encoding,
                                  :widths => []) }

      let(:width_calculator) {
        PDF::Reader::WidthCalculator::BuiltIn.new(font)
      }

      it "returns width 722 for code point 65 (A)" do
        expect(width_calculator.glyph_width(65)).to eq(722)
      end
    end
  end
end
