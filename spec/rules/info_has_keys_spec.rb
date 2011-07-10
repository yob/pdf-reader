require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::InfoHasKeys do

  it "fail files with no Title entry in the Info dict" do
    filename = pdf_spec_file("no_document_id")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::InfoHasKeys.new(:Title)

    chk.check_hash(ohash).should_not be_empty
  end

  it "pass files with a Title entry in the Info dict" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::InfoHasKeys.new(:Title)

    chk.check_hash(ohash).should be_empty
  end

end
