# coding: utf-8

require "spec_helper"

describe PDF::Reader::WidthCalculator::TypeZero do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:descendants) { [double(:glyph_width    => 50)] }
    let!(:font)        { double(:descendantfonts => descendants) }
    subject            { PDF::Reader::WidthCalculator::TypeZero.new(font)}
  end
end

describe PDF::Reader::WidthCalculator::TypeZero, "#glyph_width" do
  context "when font#descendantfonts is defined" do
    let!(:descendants) { [double(:glyph_width    => 50)] }
    let!(:font)        { double(:descendantfonts => descendants) }
    subject            { PDF::Reader::WidthCalculator::TypeZero.new(font)}

    it "should delegate the width calculation to the first descendant font" do
      subject.glyph_width(10).should == 50
    end
  end
end
