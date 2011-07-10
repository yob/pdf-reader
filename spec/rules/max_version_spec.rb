require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MaxVersion do

  it "correctly fail files with a higher version" do
    filename = pdf_spec_file("version_1_4")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::MaxVersion.new("1.3")

    chk.check_hash(ohash).should_not be_empty
  end

  it "correctly pass files with an equal version" do
    filename  = pdf_spec_file("version_1_4")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::MaxVersion.new("1.4")

    chk.check_hash(ohash).should be_empty
  end

  it "correctly pass files with a lower version" do
    filename  = pdf_spec_file("version_1_4")
    ohash    = PDF::Reader::ObjectHash.new(filename)
    chk      = Preflight::Rules::MaxVersion.new("1.5")

    chk.check_hash(ohash).should be_empty
  end

end
