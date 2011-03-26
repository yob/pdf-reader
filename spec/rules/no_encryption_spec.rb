require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::NoEncryption do

  it "correctly fail encrypted files" do
    filename = pdf_spec_file("encrypted")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::NoEncryption.new

    chk.message(ohash).should be_a(String)
  end

  it "correctly pass unencrypted files" do
    filename = pdf_spec_file("version_1_4")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::NoEncryption.new

    chk.message(ohash).should be_nil
  end

end
