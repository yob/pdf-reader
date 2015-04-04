# coding: utf-8

require "spec_helper"

describe PDF::Reader::WidthCalculator::BuiltIn do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:font) { double(:basefont => :Helvetica) }
    subject     { PDF::Reader::WidthCalculator::BuiltIn.new(font)}
  end
end

describe PDF::Reader::WidthCalculator::BuiltIn, "#initialize" do
  context "when the basefont is one of the 14 standard fonts" do
    let!(:font)        { double(:basefont => :Helvetica) }

    it "should initialize with no errors" do
      expect {
        PDF::Reader::WidthCalculator::BuiltIn.new(font)
      }.not_to raise_error
    end
  end

  context "when the basefont is not one of the 14 standard fonts" do
    let!(:font)        { double(:basefont => :Foo) }

    it "should raise an error" do
      expect {
        PDF::Reader::WidthCalculator::BuiltIn.new(font)
      }.to raise_error(ArgumentError)
    end
  end
end

describe PDF::Reader::WidthCalculator::BuiltIn, "#glyph_width" do
    let!(:encoding)     { PDF::Reader::Encoding.new(:StandardEncoding) }
    let!(:font)         { double(:basefont => :Helvetica,
                                 :subtype => :TrueType,
                                 :encoding => encoding) }

    subject(:width_calculator) {
      PDF::Reader::WidthCalculator::BuiltIn.new(font)
    }

    it "should not raise an error for code point 160 (non breaking space)" do
      lambda {
        width_calculator.glyph_width(160)
      }.should_not raise_error
    end
end
