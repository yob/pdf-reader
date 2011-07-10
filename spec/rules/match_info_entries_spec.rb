require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MatchInfoEntries do

  it "fail files with no GTS_PDFXVersion entry in the Info dict" do
    filename = pdf_spec_file("no_document_id")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /PDF\/X/)

    chk.check_hash(ohash).should_not be_empty
  end

  it "pass files with no GTS_PDFXVersion entry in the Info dict" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::MatchInfoEntries.new(:GTS_PDFXVersion => /PDF\/X/)

    chk.check_hash(ohash).should be_empty
  end

end
