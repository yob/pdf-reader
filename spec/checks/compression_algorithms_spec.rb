require File.dirname(__FILE__) + "/../spec_helper"

describe PDF::Preflight::Checks::CompressionAlgorithms do

  it "correctly fail files with a disallowed compression algorithm" do
    filename = pdf_spec_file("jbig2")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = PDF::Preflight::Checks::CompressionAlgorithms.new(:FlateDecode)

    chk.message(ohash).should be_a(String)
  end

  it "correctly pass files without a disallowed compression algorithm" do
    filename = pdf_spec_file("version_1_4")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = PDF::Preflight::Checks::CompressionAlgorithms.new(:FlateDecode)

    chk.message(ohash).should be_nil
  end

end
