$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

# expose the xrefs hash inside the XRef class so we can ensure it's built correctly
class PDF::Reader::OffsetTable
  attr_reader :xref
end

context PDF::Reader::OffsetTable, "load_offsets method" do

  specify "should load all xrefs corectly" do
    filename = File.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    tbl      = PDF::Reader::OffsetTable.new(filename)
    tbl.xref.keys.size.should eql(15) # 1 xref table with 16 items (ignore the first)
  end

  specify "should load all xrefs corectly" do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-unicode.pdf")
    @tbl  = PDF::Reader::OffsetTable.new(@file)
    @tbl.xref.keys.size.should eql(57) # 1 xref table with 58 items (ignore the first)
  end

  specify "should load all xrefs corectly" do
    @file = File.new(File.dirname(__FILE__) + "/data/openoffice-2.2.pdf")
    @tbl = PDF::Reader::OffsetTable.new(@file)
    @tbl.xref.keys.size.should eql(28) # 1 xref table with 29 items (ignore the first)
  end

  specify "should load all xrefs corectly" do
    @file = File.new(File.dirname(__FILE__) + "/data/pdflatex.pdf")
    @tbl = PDF::Reader::OffsetTable.new(@file)
    @tbl.xref.keys.size.should eql(353) # 1 xref table with 360 items (but a bunch are ignored)
  end

  specify "should load all xrefs corectly from a PDF that has multiple xref sections with subsections" do
    @file = File.new(File.dirname(__FILE__) + "/data/xref_subsections.pdf")
    @tbl = PDF::Reader::OffsetTable.new(@file)
    @tbl.xref.keys.size.should eql(66)
  end
end

context PDF::Reader::OffsetTable, "when operating on a pdf with no trailer" do

  specify "should raise an error when attempting to locate the xref table" do
    @file = File.new(File.dirname(__FILE__) + "/data/invalid/no_trailer.pdf")
    lambda { 
      PDF::Reader::OffsetTable.new(@file)
    }.should raise_error(PDF::Reader::MalformedPDFError)
  end
end

context PDF::Reader::OffsetTable, "when operating on a pdf with a trailer that isn't a dict" do

  specify "should raise an error when attempting to locate the xref table" do
    @file = File.new(File.dirname(__FILE__) + "/data/invalid/trailer_is_not_a_dict.pdf")
    lambda { 
      PDF::Reader::OffsetTable.new(@file)
    }.should raise_error(PDF::Reader::MalformedPDFError)
  end

end

context PDF::Reader::OffsetTable, "when operating on a pdf that uses an XRef Stream" do

  before(:each) do
    @file = File.new(File.dirname(__FILE__) + "/data/cross_ref_stream.pdf")
    @tbl = PDF::Reader::OffsetTable.new(@file)
  end

  specify "should correctly load all object locations" do
    @tbl.xref.keys.size.should eql(327) # 1 xref stream with 344 items (ignore the 17 free objects)
  end

  specify "should load type 1 objects references" do
    @tbl.xref[66][0].should eql(298219)
  end

  specify "should load type 2 objects references" do
    @tbl.xref[281][0].should eql(PDF::Reader::Reference.new(341,0))
  end

end
