# coding: utf-8

require "spec_helper"

describe PDF::Reader::WidthCalculator::BuiltIn do
  it_behaves_like "a WidthCalculator duck type" do
    let!(:font) { double(:basefont => :Helvetica) }
    subject     { PDF::Reader::WidthCalculator::BuiltIn.new(font)}
  end
end

describe PDF::Reader::WidthCalculator::BuiltIn, "#glyph_width" do
  it "should raise an UnknownGlyphWidthError when the glyph width is unknown" do
    lambda { 
      file = File.new(pdf_spec_file("unknown_glyph_width_sample"))
      pdf = PDF::Reader.new(file)
      
      # this is a three page PDF.
      # only the second page contains the unknown glypth width
      pdf.pages[1].text        

    }.should raise_error(PDF::Reader::UnknownGlyphWidthError)
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
  context "With Helvetica, StandardEncoding and no Widths" do
    let!(:encoding)     { PDF::Reader::Encoding.new(:StandardEncoding) }
    let!(:font)         { double(:basefont => :Helvetica,
                                :subtype => :TrueType,
                                :encoding => encoding,
                                :widths => []) }

    let(:width_calculator) {
      PDF::Reader::WidthCalculator::BuiltIn.new(font)
    }

    it "should return width 0 for code point 160(non breaking space)" do
      expect(width_calculator.glyph_width(160)).to eq(0)
    end

    it "should return width 0 for code point 157(unknown)" do
      expect(width_calculator.glyph_width(157)).to eq(0)
    end
  end
end