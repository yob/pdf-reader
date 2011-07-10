require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::OutputIntentForPdfx do

  it "fail files with no OutputIntent for PDF/X" do
    filename = pdf_spec_file("encrypted")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::OutputIntentForPdfx.new

    chk.check_hash(ohash).should_not be_empty
  end

  it "pass files with a single OutputIntent for PDF/X" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::DocumentId.new

    chk.check_hash(ohash).should be_empty
  end

end
