$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

module BufferHelper
  def parse_string (r)
    PDF::Reader::Buffer.new(StringIO.new(r))
  end
end

context PDF::Reader::Buffer, "pop method" do
  include BufferHelper

  specify "should correctly return a simple token - 1" do
    buf = parse_string("aaa")

    buf.pop.should eql("aaa")
    buf.pop.should be_nil
  end

  specify "should correctly return a simple token - 2" do
    buf = parse_string("1.0")

    buf.pop.should eql("1.0")
    buf.pop.should be_nil
  end

  specify "should correctly return two simple tokens" do
    buf = parse_string("aaa 1.0")

    buf.pop.should eql("aaa")
    buf.pop.should eql("1.0")
    buf.pop.should be_nil
  end

  specify "should correctly tokenise opening delimiters" do
    buf = parse_string("(<[{/%")

    buf.pop.should eql("(")
    buf.pop.should eql("<")
    buf.pop.should eql("[")
    buf.pop.should eql("{")
    buf.pop.should eql("/")
    buf.pop.should eql("%")
    buf.pop.should be_nil
  end

  specify "should correctly tokenise closing delimiters" do
    buf = parse_string(")>]}")

    buf.pop.should eql(")")
    buf.pop.should eql(">")
    buf.pop.should eql("]")
    buf.pop.should eql("}")
    buf.pop.should be_nil
  end

  specify "should correctly tokenise hash delimiters" do
    buf = parse_string("<<aaa>>")

    buf.pop.should eql("<<")
    buf.pop.should eql("aaa")
    buf.pop.should eql(">>")
    buf.pop.should be_nil
  end

  specify "should correctly return simple tokens with delimiters" do
    buf = parse_string("<aaa><bbb>")

    buf.pop.should eql("<")
    buf.pop.should eql("aaa")
    buf.pop.should eql(">")
    buf.pop.should eql("<")
    buf.pop.should eql("bbb")
    buf.pop.should eql(">")
    buf.pop.should be_nil
  end

  specify "should correctly return two name tokens" do
    buf = parse_string("/Type/Pages")

    buf.pop.should eql("/")
    buf.pop.should eql("Type")
    buf.pop.should eql("/")
    buf.pop.should eql("Pages")
    buf.pop.should be_nil
  end

end

context PDF::Reader::Buffer, "empty? method" do
  include BufferHelper

  specify "should correctly return false if there are remaining tokens" do
    buf = parse_string("aaa")

    buf.empty?.should be_false
  end

  specify "should correctly return true if there are no remaining tokens" do
    buf = parse_string("aaa")

    buf.empty?.should be_false
    buf.pop
    buf.empty?.should be_true
  end
end

context PDF::Reader::Buffer, "find_first_xref_offset method" do

  specify "should find the first xref offset from cairo-basic.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(9243)
  end

  specify "should find the first xref offset from cairo-unicode.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-unicode.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(136174)
  end

  specify "should find the first xref offset from prince1.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/prince1.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(678715)
  end

  specify "should find the first xref offset from prince2.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/prince2.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(941440)
  end

  specify "should find the first xref offset from pdfwriter-manual.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/pdfwriter-manual.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(275320)
  end

  specify "should find the first xref offset from pdf-distiller.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/pdf-distiller.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(173)
  end

  specify "should find the first xref offset from pdflatex.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/pdflatex.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(152898)
  end

  specify "should find the first xref offset from openoffice-2.2.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/openoffice-2.2.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(36961)
  end

  specify "should raise an exception when buffer doesn't contain an EOF marker" do
    @file = File.new(File.dirname(__FILE__) + "/data/invalid/no_eof.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    lambda { @buffer.find_first_xref_offset }.should raise_error(PDF::Reader::MalformedPDFError)
  end

end
