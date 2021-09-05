# typed: false
# coding: utf-8

describe PDF::Reader::WidthCalculator::TrueType do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:descriptor) { double(:missing_width => 50) }
    let!(:font)       { double(:font_descriptor => descriptor,
                               :widths          => [20,30,40],
                               :first_char      => 10) }
    subject           { PDF::Reader::WidthCalculator::TrueType.new(font)}
  end

  describe "#glyph_width" do
    context "when font#widths is defined" do
      let!(:descriptor) { double(:missing_width => 50) }
      let!(:font)       { double(:font_descriptor => descriptor,
                                :widths          => [20,30,40],
                                :first_char      => 10) }
      subject           { PDF::Reader::WidthCalculator::TrueType.new(font)}

      context "when the glyph code is less than font#first_char" do
        it "returns the missing width" do
          expect(subject.glyph_width(9)).to eq(50)
        end
      end
      context "when the glyph code is equal to greater than font#first_char" do
        it "returns the correct width" do
          expect(subject.glyph_width(10)).to eq(20)
        end
      end
    end
    context "when font#widths is undefined" do
      let!(:descriptor) { double(:missing_width => 50,
                                :glyph_width => 60,
                                :glyph_to_pdf_scale_factor => 1) }
      let!(:font)       { double(:font_descriptor => descriptor,
                                :widths          => nil,
                                :first_char      => 10) }
      subject           { PDF::Reader::WidthCalculator::TrueType.new(font)}

      it "fetches the width from the descriptor" do
        expect(subject.glyph_width(10)).to eq(60)
      end
    end
  end
end
