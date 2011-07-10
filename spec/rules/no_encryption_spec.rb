require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::NoEncryption do

  it "correctly fail encrypted files" do
    filename = pdf_spec_file("encrypted")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::NoEncryption.new

    chk.check_hash(ohash).should_not be_empty
  end

  it "correctly pass unencrypted files" do
    filename = pdf_spec_file("version_1_4")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::NoEncryption.new

    chk.check_hash(ohash).should be_empty
  end

end
