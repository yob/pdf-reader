require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::PrintBoxes do

  it "pass files with required page boxes" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    receiver = Preflight::Rules::PrintBoxes.new
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

  it "pass files with required page boxes stored in a parent Pages object" do
    filename = pdf_spec_file("inherited_page_attributes")
    receiver = Preflight::Rules::PrintBoxes.new
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

  it "fail files with no ArtBox or TrimBox" do
    filename = pdf_spec_file("no_artbox_or_trimbox")
    receiver = Preflight::Rules::PrintBoxes.new
    PDF::Reader.file(filename, receiver)

    receiver.messages.should_not be_empty
  end

  it "fail files with an ArtBox and TrimBox" do
    filename = pdf_spec_file("artbox_and_trimbox")
    receiver = Preflight::Rules::PrintBoxes.new
    PDF::Reader.file(filename, receiver)

    receiver.messages.should_not be_empty
  end

end
