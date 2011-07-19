# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

# expose the xrefs hash inside the XRef class so we can ensure it's built correctly
class PDF::Reader::XRef
  attr_reader :xref
end

describe PDF::Reader::XRef, "load_offsets method" do

  it "should load all xrefs corectly" do
    filename = File.new(pdf_spec_file("cairo-basic"))
    tbl      = PDF::Reader::XRef.new(filename)
    tbl.xref.keys.size.should eql(15) # 1 xref table with 16 items (ignore the first)
  end

  it "should load all xrefs corectly" do
    @file = File.new(pdf_spec_file("cairo-unicode"))
    @tbl  = PDF::Reader::XRef.new(@file)
    @tbl.xref.keys.size.should eql(57) # 1 xref table with 58 items (ignore the first)
  end

  it "should load all xrefs corectly" do
    @file = File.new(pdf_spec_file("openoffice-2.2"))
    @tbl = PDF::Reader::XRef.new(@file)
    @tbl.xref.keys.size.should eql(28) # 1 xref table with 29 items (ignore the first)
  end

  it "should load all xrefs corectly" do
    @file = File.new(pdf_spec_file("pdflatex"))
    @tbl = PDF::Reader::XRef.new(@file)
    @tbl.xref.keys.size.should eql(353) # 1 xref table with 360 items (but a bunch are ignored)
  end

  it "should load all xrefs corectly from a PDF that has multiple xref sections with subsections and xref streams" do
    @file = File.new(pdf_spec_file("xref_subsections"))
    @tbl = PDF::Reader::XRef.new(@file)
    @tbl.xref.keys.size.should eql(539)
  end
end

describe PDF::Reader::XRef, "when operating on a pdf with no trailer" do

  it "should raise an error when attempting to locate the xref table" do
    @file = File.new(pdf_spec_file("no_trailer"))
    lambda {
      PDF::Reader::XRef.new(@file)
    }.should raise_error(PDF::Reader::MalformedPDFError)
  end
end

describe PDF::Reader::XRef, "when operating on a pdf with a trailer that isn't a dict" do

  it "should raise an error when attempting to locate the xref table" do
    @file = File.new(pdf_spec_file("trailer_is_not_a_dict"))
    lambda {
      PDF::Reader::XRef.new(@file)
    }.should raise_error(PDF::Reader::MalformedPDFError)
  end

end

describe PDF::Reader::XRef, "when operating on a pdf that uses an XRef Stream" do

  before(:each) do
    @file = File.new(pdf_spec_file("cross_ref_stream"))
    @tbl = PDF::Reader::XRef.new(@file)
  end

  it "should correctly load all object locations" do
    @tbl.xref.keys.size.should eql(327) # 1 xref stream with 344 items (ignore the 17 free objects)
  end

  it "should load type 1 objects references" do
    @tbl.xref[66][0].should eql(298219)
  end

  it "should load type 2 objects references" do
    @tbl.xref[281][0].should eql(PDF::Reader::Reference.new(341,0))
  end

end
