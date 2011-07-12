require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Rules::MinPpi do

  it "pass files with a no raster images" do
    filename = pdf_spec_file("pdfx-1a-subsetting")
    rule     = Preflight::Rules::MinPpi.new(300)

    PDF::Reader.open(filename) do |reader|
      reader.page(1).walk(rule)
      rule.messages.should be_empty
    end
  end

  it "pass files with only 300 ppi raster images" do
    filename = pdf_spec_file("300ppi")
    rule     = Preflight::Rules::MinPpi.new(300)

    PDF::Reader.open(filename) do |reader|
      reader.page(1).walk(rule)
      rule.messages.should be_empty
    end
  end

  it "fail files with a 75ppi raster image" do
    filename = pdf_spec_file("72ppi")
    rule     = Preflight::Rules::MinPpi.new(300)

    PDF::Reader.open(filename) do |reader|
      reader.page(1).walk(rule)
      rule.messages.should_not be_empty
    end
  end

  it "pass files with no raster images that use a Form XObject" do
    filename = pdf_spec_file("form_xobject")
    rule     = Preflight::Rules::MinPpi.new(300)

    PDF::Reader.open(filename) do |reader|
      reader.page(1).walk(rule)
      rule.messages.should be_empty
    end
  end

end
