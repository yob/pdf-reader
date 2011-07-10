require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::DocumentId do

  it "fail files with no document ID in the trailer" do
    filename = pdf_spec_file("no_document_id")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::DocumentId.new

    chk.check_hash(ohash).should_not be_empty
  end

  it "pass files with a document ID in the trailer" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::DocumentId.new

    chk.check_hash(ohash).should be_empty
  end

end
