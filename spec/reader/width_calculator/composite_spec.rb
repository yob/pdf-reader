# typed: false
# coding: utf-8

describe PDF::Reader::WidthCalculator::Composite do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:font)       { double(:cid_default_width => 50,
                                :cid_widths        => [10,[30,40]])
                      }
    subject           { PDF::Reader::WidthCalculator::Composite.new(font)}
  end

  describe "#glyph_width" do
    context "when font#cid_default_width is defined" do
      let!(:font)       { double(:cid_default_width => 50,
                                  :cid_widths        => [10,[30,40]])
                        }
      subject           { PDF::Reader::WidthCalculator::Composite.new(font)}

      context "when the glyph code is provided in cid_widths" do
        it "returns the correct width" do
          expect(subject.glyph_width(10)).to eq(30)
        end
      end
      context "when the glyph code is equal to greater than font#first_char" do
        it "returns the default width" do
          expect(subject.glyph_width(9)).to eq(50)
        end
      end
    end
  end
end
