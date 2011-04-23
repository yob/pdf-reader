require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::BoxNesting do

  it "pass files with page boxes nested appropriately" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    receiver = Preflight::Rules::BoxNesting.new
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

  it "pass files with inherited page boxes nested appropriately" do
    filename = pdf_spec_file("inherited_page_attributes")
    receiver = Preflight::Rules::BoxNesting.new
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

  it "fail files with a BleedBox smaller than MediaBox" do
    filename = pdf_spec_file("bleedbox_larger_than_mediabox")
    receiver = Preflight::Rules::BoxNesting.new
    PDF::Reader.file(filename, receiver)

    receiver.messages.should_not be_empty
  end

end
