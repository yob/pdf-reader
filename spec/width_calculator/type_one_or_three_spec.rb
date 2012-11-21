# coding: utf-8

require "spec_helper"

describe PDF::Reader::WidthCalculator::TypeOneOrThree do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:descriptor) { double(:missing_width => 50) }
    let!(:font)       { double(:font_descriptor => descriptor,
                               :widths          => [20,30,40],
                               :first_char      => 10) }
    subject           { PDF::Reader::WidthCalculator::TypeOneOrThree.new(font)}
  end
end

describe PDF::Reader::WidthCalculator::TypeOneOrThree, "#glyph_width" do
  context "when font#widths is defined" do
    let!(:descriptor) { double(:missing_width => 50) }
    let!(:font)       { double(:font_descriptor => descriptor,
                               :widths          => [20,30,40],
                               :first_char      => 10) }
    subject           { PDF::Reader::WidthCalculator::TypeOneOrThree.new(font)}

    context "when the glyph code is less than font#first_char" do
      it "should return the missing width" do
        subject.glyph_width(9).should == 50
      end
    end
    context "when the glyph code is equal to greater than font#first_char" do
      it "should return the correct width" do
        subject.glyph_width(10).should == 20
      end
    end
  end
  context "when font#widths is undefined" do
    let!(:descriptor) { double(:missing_width => 50) }
    let!(:font)       { double(:font_descriptor => descriptor,
                               :widths          => nil,
                               :first_char      => 10) }
    subject           { PDF::Reader::WidthCalculator::TypeOneOrThree.new(font)}

    it "should return 0" do
      subject.glyph_width(10).should == 0
    end
  end
end
