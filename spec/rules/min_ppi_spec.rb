require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MinPpi do

  it "pass files with a no raster images" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    receiver = Preflight::Rules::MinPpi.new(300)
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

  it "pass files with only 300 ppi raster images" do
    filename  = pdf_spec_file("300ppi")
    receiver = Preflight::Rules::MinPpi.new(300)
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

  it "fail files with a 75ppi raster image" do
    filename  = pdf_spec_file("72ppi")
    receiver = Preflight::Rules::MinPpi.new(300)
    PDF::Reader.file(filename, receiver)

    receiver.messages.should_not be_empty
  end

  it "pass files with no raster images that use a Form XObject" do
    filename  = pdf_spec_file("form_xobject")
    receiver = Preflight::Rules::MinPpi.new(300)
    PDF::Reader.file(filename, receiver)

    receiver.messages.should be_empty
  end

end
