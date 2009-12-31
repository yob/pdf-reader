$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'pdf/reader'

module BufferHelper
  def parse_string (r)
    PDF::Reader::Buffer.new(StringIO.new(r))
  end
end

context PDF::Reader::Buffer, "token method" do
  include BufferHelper

  specify "should correctly return a simple token - 1" do
    buf = parse_string("aaa")

    buf.token.should eql("aaa")
    buf.token.should be_nil
  end

  specify "should correctly return a simple token - 2" do
    buf = parse_string("1.0")

    buf.token.should eql("1.0")
    buf.token.should be_nil
  end

  specify "should correctly return two simple tokens" do
    buf = parse_string("aaa 1.0")

    buf.token.should eql("aaa")
    buf.token.should eql("1.0")
    buf.token.should be_nil
  end

  specify "should correctly tokenise opening delimiters" do
    buf = parse_string("(<[{/%")

    buf.token.should eql("(")
    buf.token.should eql("<")
    buf.token.should eql("[")
    buf.token.should eql("{")
    buf.token.should eql("/")
    buf.token.should eql("%")
    buf.token.should be_nil
  end

  specify "should correctly tokenise closing delimiters" do
    buf = parse_string(")>]}")

    buf.token.should eql(")")
    buf.token.should eql(">")
    buf.token.should eql("]")
    buf.token.should eql("}")
    buf.token.should be_nil
  end

  specify "should correctly tokenise hash delimiters" do
    buf = parse_string("<<aaa>>")

    buf.token.should eql("<<")
    buf.token.should eql("aaa")
    buf.token.should eql(">>")
    buf.token.should be_nil
  end

  specify "should correctly return simple tokens with delimiters" do
    buf = parse_string("<aaa><bbb>")

    buf.token.should eql("<")
    buf.token.should eql("aaa")
    buf.token.should eql(">")
    buf.token.should eql("<")
    buf.token.should eql("bbb")
    buf.token.should eql(">")
    buf.token.should be_nil
  end

  specify "should correctly return two name tokens" do
    buf = parse_string("/Type/Pages")

    buf.token.should eql("/")
    buf.token.should eql("Type")
    buf.token.should eql("/")
    buf.token.should eql("Pages")
    buf.token.should be_nil
  end

  specify "should tokenise a dict correctly" do
    buf = parse_string("/Registry (Adobe) /Ordering (Japan1) /Supplement")
    buf.token.should eql("/")
    buf.token.should eql("Registry")
    buf.token.should eql("(")
    buf.token.should eql("Adobe")
    buf.token.should eql(")")
    buf.token.should eql("/")
    buf.token.should eql("Ordering")
    buf.token.should eql("(")
    buf.token.should eql("Japan1")
    buf.token.should eql(")")
    buf.token.should eql("/")
    buf.token.should eql("Supplement")
  end

  specify "should tokenise a string without a % correctly" do
    buf = parse_string("(James)")
    buf.token.should eql("(")
    buf.token.should eql("James")
    buf.token.should eql(")")
  end

  specify "should tokenise a string with a % correctly" do
    buf = parse_string("(James%Healy)")
    buf.token.should eql("(")
    buf.token.should eql("James")
    buf.token.should eql("%")
    buf.token.should eql("Healy")
    buf.token.should eql(")")
  end

  specify "should tokenise a string with comments correctly" do
    buf = parse_string("(James%Healy) % this is a comment\n(")
    buf.token.should eql("(")
    buf.token.should eql("James")
    buf.token.should eql("%")
    buf.token.should eql("Healy")
    buf.token.should eql(")")
    buf.token.should eql("(")
  end
  
  specify "should correctly return an indirect reference" do
    buf = parse_string("aaa 1 0 R bbb")

    buf.token.should eql("aaa")
    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should eql("bbb")
    buf.token.should be_nil
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
    buf.token
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
