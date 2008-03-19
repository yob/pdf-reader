$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

context "The PDF::Reader::Buffer class when operating on the cairo-basic PDF" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end
  
  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(9243)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.4")
  end

end

context "The PDF::Reader::Buffer class when operating on the cairo-unicode PDF" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-unicode.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(136174)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.4")
  end

end

context "The PDF::Reader::Buffer class when operating on the prince1 PDF" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/prince1.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(678715)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.4")
  end

end

context "The PDF::Reader::Buffer class when operating on the prince2 PDF" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/prince2.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(941440)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.4")
  end

end

context "The PDF::Reader::Buffer class when operating on the pdfwriter manual" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/pdfwriter-manual.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(275320)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.3")
  end

end

context "The PDF::Reader::Buffer class when operating on the pdf-distiller PDF" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/pdf-distiller.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  # this file uses just a \r as an EOL marker, so check we handle it properly
  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(173)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.2")
  end

end

context "The PDF::Reader::Buffer class when operating on the pdflatex PDF" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/pdflatex.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(152898)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.4")
  end
end

context "The PDF::Reader::Buffer class when operating on the openoffice-2.2 PDF" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/openoffice-2.2.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  specify "should find the first xref offset correctly" do
    @buffer.find_first_xref_offset.should eql(36961)
  end

  specify "should be able to read the PDF header correctly" do
    @buffer.seek(0).read(8).should eql("%PDF-1.4")
  end

  specify "should be able to read all bytes up to 1.4 and leave the cursor in the right location" do
    @buffer.seek(0).read_until("1.4").should eql("%PDF-")
    @buffer.pos.should eql(5)
  end

end

context "The PDF::Reader::Buffer class when operating on a PDF with no EOF marker" do

  setup do
    @file = File.new(File.dirname(__FILE__) + "/data/invalid/no_eof.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)
  end

  specify "should raise an exception when trying to find the xref offset" do
    lambda { @buffer.find_first_xref_offset }.should raise_error(PDF::Reader::MalformedPDFError)
  end

end

