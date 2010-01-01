$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

# expose the xrefs hash inside the XRef class so we can ensure it's built correctly
class PDF::Reader::XRef
  attr_reader :xref
end

context "The PDF::Reader::XRef class when operating on the cairo-basic PDF" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(15) # 1 xref table with 16 items (ignore the first)
  end

  specify "should not attempt to translate a non reference into an object" do
    ref = "James"
    @xref.load
    obj, stream = @xref.object(ref)
    obj.should eql(ref)
  end

  specify "should return a stream-less object correctly" do
    ref = PDF::Reader::Reference.new(6,0)
    @xref.load
    @xref.object(ref).should eql(267)
  end
end

context "The PDF::Reader::XRef class when operating on the cairo-unicode PDF" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-unicode.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(57) # 1 xref table with 58 items (ignore the first)
  end
end

context "The PDF::Reader::XRef class when operating on the openoffice-2.2 PDF" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/openoffice-2.2.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(28) # 1 xref table with 29 items (ignore the first)
  end

end

context "The PDF::Reader::XRef class when operating on the pdf-distiller PDF" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/pdf-distiller.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(536) # 2 xref tables with 55+481 items
  end
end

context "The PDF::Reader::XRef class when operating on the prince1 PDF" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/prince1.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(39) # 1 xref table with 40 items (ignore the first)
  end

end

context "The PDF::Reader::XRef class when operating on the prince2 PDF" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/prince2.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(135) # 1 xref table with 136 items (ignore the first)
  end

end

context "The PDF::Reader::XRef class when operating on the pdflatex PDF" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/pdflatex.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(353) # 1 xref table with 360 items (but a bunch are ignored)
  end

end

context "The PDF::Reader::XRef class when operating on the pdfwriter manual" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/pdfwriter-manual.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(1242) # 1 xref table with 1243 items (ignore the first)
  end

end

context "The PDF::Reader::XRef class when operating on a PDF that has been updated in Adobe Acrobat (and therefore has multiple xref sections with subsections)" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/xref_subsections.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should load all xrefs corectly" do
    @xref.load
    @xref.xref.keys.size.should eql(66)
  end

end

context "The PDF::Reader::XRef class when operating on a pdf with no trailer" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/invalid/no_trailer.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should raise an error when attempting to locate the xref table" do
    lambda { @xref.load}.should raise_error(PDF::Reader::MalformedPDFError)
  end

end

context "The PDF::Reader::XRef class when operating on a pdf with a trailer that isn't a dict" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/invalid/trailer_is_not_a_dict.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should raise an error when attempting to locate the xref table" do
    lambda { @xref.load}.should raise_error(PDF::Reader::MalformedPDFError)
  end

end

context "The PDF::Reader::XRef class when operating on a pdf that uses an XRef Stream" do

  before do
    @file = File.new(File.dirname(__FILE__) + "/data/cross_ref_stream.pdf")
    @xref = PDF::Reader::XRef.new(@file)
  end

  specify "should raise an error when attempting to locate the xref table" do
    lambda { @xref.load}.should raise_error(PDF::Reader::UnsupportedFeatureError)
  end

end
