# typed: false
# coding: utf-8

describe PDF::Reader::WidthCalculator::TypeZero do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:descendants) { [double(:glyph_width    => 50)] }
    let!(:font)        { double(:descendantfonts => descendants) }
    subject            { PDF::Reader::WidthCalculator::TypeZero.new(font)}
  end

  describe "#glyph_width" do
    context "when font#descendantfonts is defined" do
      let!(:descendants) { [double(:glyph_width    => 50)] }
      let!(:font)        { double(:descendantfonts => descendants) }
      subject            { PDF::Reader::WidthCalculator::TypeZero.new(font)}

      it "delegates the width calculation to the first descendant font" do
        expect(subject.glyph_width(10)).to eq(50)
      end
    end
  end
end
