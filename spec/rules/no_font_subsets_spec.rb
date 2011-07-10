require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::NoFontSubsets do

  it "fail files with a subsetted TTF font" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::NoFontSubsets.new

    chk.check_hash(ohash).should_not be_empty
  end

  it "pass files with a complete TTF font" do
    filename = pdf_spec_file("pdfx-1a-no-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::NoFontSubsets.new

    chk.check_hash(ohash).should be_empty
  end

end
