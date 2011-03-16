require File.dirname(__FILE__) + "/../spec_helper"

describe PDF::Preflight::Checks::NoEncryption do

  it "correctly fail encrypted files" do
    filename = pdf_spec_file("encrypted")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = PDF::Preflight::Checks::NoEncryption.new

    chk.message(ohash).should be_a(String)
  end

  it "correctly pass unencrypted files" do
    filename = pdf_spec_file("version_1_4")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = PDF::Preflight::Checks::NoEncryption.new

    chk.message(ohash).should be_nil
  end

end
