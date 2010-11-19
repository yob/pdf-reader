# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Buffer, "token method" do
  include BufferHelper
  include EncodingHelper

  it "should return nil when there's no IO left" do
    buf = parse_string("aaa")

    buf.token
    buf.token.should be_nil
  end

  it "should correctly return a simple token - 1" do
    buf = parse_string("aaa")

    buf.token.should eql("aaa")
    buf.token.should be_nil
  end

  it "should correctly return a simple token - 2" do
    buf = parse_string("1.0")

    buf.token.should eql("1.0")
    buf.token.should be_nil
  end

  it "should correctly return two simple tokens" do
    buf = parse_string("aaa 1.0")

    buf.token.should eql("aaa")
    buf.token.should eql("1.0")
    buf.token.should be_nil
  end

  it "should correctly tokenise opening delimiters" do
    buf = parse_string("<[{/(")

    buf.token.should eql("<")
    buf.token.should eql(">") # auto adds closing hex string delim
    buf.token.should eql("[")
    buf.token.should eql("{")
    buf.token.should eql("/")
    buf.token.should eql("(")
    buf.token.should eql(")") # auto adds closing literal string delim
    buf.token.should be_nil
  end

  it "should correctly tokenise closing delimiters" do
    buf = parse_string(")>]}")

    buf.token.should eql(")")
    buf.token.should eql(">")
    buf.token.should eql("]")
    buf.token.should eql("}")
    buf.token.should be_nil
  end

  it "should correctly tokenise hash delimiters" do
    buf = parse_string("<<aaa>>")

    buf.token.should eql("<<")
    buf.token.should eql("aaa")
    buf.token.should eql(">>")
    buf.token.should be_nil
  end

  it "should correctly return simple tokens with delimiters" do
    buf = parse_string("<aaa><bbb>")

    buf.token.should eql("<")
    buf.token.should eql("aaa")
    buf.token.should eql(">")
    buf.token.should eql("<")
    buf.token.should eql("bbb")
    buf.token.should eql(">")
    buf.token.should be_nil
  end

  it "should correctly return two name tokens" do
    buf = parse_string("/Type/Pages")

    buf.token.should eql("/")
    buf.token.should eql("Type")
    buf.token.should eql("/")
    buf.token.should eql("Pages")
    buf.token.should be_nil
  end

  it "should tokenise a dict correctly" do
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

  it "should tokenise a string without a % correctly" do
    buf = parse_string("(James)")
    buf.token.should eql("(")
    buf.token.should eql("James")
    buf.token.should eql(")")
  end

  it "should tokenise a literal string with a % correctly" do
    buf = parse_string("(James%Healy)")
    buf.token.should eql("(")
    buf.token.should eql("James%Healy")
    buf.token.should eql(")")
  end

  it "should tokenise a hex string with a space correctly" do
    buf = parse_string("<AA BB>")
    buf.token.should eql("<")
    buf.token.should eql("AABB")
    buf.token.should eql(">")
  end

  it "should tokenise a string with comments correctly" do
    buf = parse_string("(James%Healy) % this is a comment\n(")
    buf.token.should eql("(")
    buf.token.should eql("James%Healy")
    buf.token.should eql(")")
    buf.token.should eql("(")
  end

  it "should tokenise a string with comments correctly" do
    buf = parse_string("James % this is a comment")
    buf.token.should eql("James")
    buf.token.should be_nil
  end

  it "should tokenise a string with an escaped, unbalanced param correctly" do
    buf = parse_string("(James \\(Code Monkey)")
    buf.token.should eql("(")
    buf.token.should eql("James \\(Code Monkey")
    buf.token.should eql(")")
  end
  
  it "should correctly return an indirect reference" do
    buf = parse_string("aaa 1 0 R bbb")

    buf.token.should eql("aaa")
    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should eql("bbb")
    buf.token.should be_nil
  end

  it "should correctly return two indirect references" do
    buf = parse_string("1 0 R 2 0 R")

    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should be_nil
  end

  it "should correctly seek to a particular byte of the IO - 1" do
    str = "aaa bbb ccc"
    buf = PDF::Reader::Buffer.new(StringIO.new(str), :seek => 4)

    buf.token.should eql("bbb")
    buf.token.should eql("ccc")
    buf.token.should be_nil
  end

  it "should correctly seek to a particular byte of the IO - 2" do
    str = "aaa bbb ccc"
    buf = PDF::Reader::Buffer.new(StringIO.new(str), :seek => 5)

    buf.token.should eql("bb")
    buf.token.should eql("ccc")
    buf.token.should be_nil
  end

  it "should correctly return a simple literal string" do
    buf = parse_string("(aaa)")

    buf.token.should eql("(")
    buf.token.should eql("aaa")
    buf.token.should eql(")")
    buf.token.should be_nil
  end

  it "should correctly return an empty literal string" do
    buf = parse_string("()")

    buf.token.should eql("(")
    buf.token.should eql(")")
    buf.token.should be_nil
  end

  it "should correctly return a simple literal string with spaces" do
    buf = parse_string("(aaa bbb)")

    buf.token.should eql("(")
    buf.token.should eql("aaa bbb")
    buf.token.should eql(")")
    buf.token.should be_nil
  end

  it "should correctly return a simple literal string with nested brackets" do
    buf = parse_string("(aaa (bbb))")

    buf.token.should eql("(")
    buf.token.should eql("aaa (bbb)")
    buf.token.should eql(")")
    buf.token.should be_nil
  end

  it "should correctly return a literal string with escaped slash followed by a closing brace" do
    buf = parse_string("(aaa\x5C\x5C)")

    buf.token.should eql("(")
    buf.token.should eql("aaa\x5C\x5C")
    buf.token.should eql(")")
    buf.token.should be_nil
  end

  it "should correctly return a literal string with three slashes followed by a closing brace" do
    buf = parse_string("(aaa\x5C\x5C\x5C))")

    buf.token.should eql("(")
    buf.token.should eql("aaa\x5C\x5C\x5C)")
    buf.token.should eql(")")
    buf.token.should be_nil
  end

  it "should correctly return a dictionary with embedded hex string" do
    buf = parse_string("<< /X <48656C6C6F> >>")
    buf.token.should eql("<<")
    buf.token.should eql("/")
    buf.token.should eql("X")
    buf.token.should eql("<")
    buf.token.should eql("48656C6C6F")
    buf.token.should eql(">")
    buf.token.should eql(">>")
  end
  it "should correctly return a dictionary with embedded hex string" do
    buf = parse_string("/Span<</ActualText<FEFF0009>>> BDC")
    buf.token.should eql("/")
    buf.token.should eql("Span")
    buf.token.should eql("<<")
    buf.token.should eql("/")
    buf.token.should eql("ActualText")
    buf.token.should eql("<")
    buf.token.should eql("FEFF0009")
    buf.token.should eql(">")
    buf.token.should eql(">>")
    buf.token.should eql("BDC")
  end

  it "should correctly return a dictionary with an indirect reference" do
    buf = parse_string("<< /X 10 0 R >>")
    buf.token.should eql("<<")
    buf.token.should eql("/")
    buf.token.should eql("X")
    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should eql(">>")
  end

  it "should correctly return a dictionary with an indirect reference and more than 10 tokens" do
    buf = parse_string("<< /X 10 0 R /Y 11 0 R /Z 12 0 R >>")
    buf.token.should eql("<<")
    buf.token.should eql("/")
    buf.token.should eql("X")
    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should eql("/")
    buf.token.should eql("Y")
    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should eql("/")
    buf.token.should eql("Z")
    buf.token.should be_a_kind_of(PDF::Reader::Reference)
    buf.token.should eql(">>")
  end

  it "should record io position" do
    buf = parse_string("aaa bbb")

    buf.pos.should eql(0)
    buf.token
    buf.pos.should eql(7)
  end

  it "should restore io position if it's been changed on us" do
    io = StringIO.new("aaa bbb")
    buf = PDF::Reader::Buffer.new(io)

    buf.pos.should eql(0)
    buf.token
    buf.token
    buf.pos.should eql(7)
    io.seek(0)

    buf.token.should be_nil
    buf.pos.should eql(7)
  end

  it "should correctly tokenise an inline image when inside a content stream" do
    io = StringIO.new("BT ID aaa bbb ccc \xF0\xF0\xF0 EI")
    buf = PDF::Reader::Buffer.new(io, :content_stream => true)

    buf.pos.should eql(0)
    buf.token.should eql("BT")
    buf.token.should eql("ID")
    buf.token.should eql(binary_string("aaa bbb ccc \xF0\xF0\xF0"))
    buf.token.should eql("EI")
  end

  it "should correctly tokenise an inline image when outside a content stream" do
    io = StringIO.new("BT ID aaa bbb ccc \xF0\xF0\xF0 EI")
    buf = PDF::Reader::Buffer.new(io, :content_stream => false)

    buf.pos.should eql(0)
    buf.token.should eql("BT")
    buf.token.should eql("ID")
    buf.token.should eql("aaa")
    buf.token.should eql("bbb")
    buf.token.should eql("ccc")
    buf.token.should eql(binary_string("\xF0\xF0\xF0"))
    buf.token.should eql("EI")
  end
end

describe PDF::Reader::Buffer, "empty? method" do
  include BufferHelper

  it "should correctly return false if there are remaining tokens" do
    buf = parse_string("aaa")

    buf.empty?.should be_false
  end

  it "should correctly return true if there are no remaining tokens" do
    buf = parse_string("aaa")

    buf.empty?.should be_false
    buf.token
    buf.empty?.should be_true
  end
end

describe PDF::Reader::Buffer, "find_first_xref_offset method" do

  it "should find the first xref offset from cairo-basic.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-basic.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(9243)
  end

  it "should find the first xref offset from cairo-unicode.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/cairo-unicode.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(136174)
  end

  it "should find the first xref offset from prince1.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/prince1.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(678715)
  end

  it "should find the first xref offset from prince2.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/prince2.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(941440)
  end

  it "should find the first xref offset from pdfwriter-manual.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/pdfwriter-manual.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(275320)
  end

  it "should find the first xref offset from pdf-distiller.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/pdf-distiller.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(173)
  end

  it "should find the first xref offset from pdflatex.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/pdflatex.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(152898)
  end

  it "should find the first xref offset from openoffice-2.2.pdf correctly" do
    @file = File.new(File.dirname(__FILE__) + "/data/openoffice-2.2.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    @buffer.find_first_xref_offset.should eql(36961)
  end

  it "should raise an exception when buffer doesn't contain an EOF marker" do
    @file = File.new(File.dirname(__FILE__) + "/data/invalid/no_eof.pdf")
    @buffer = PDF::Reader::Buffer.new(@file)

    lambda { @buffer.find_first_xref_offset }.should raise_error(PDF::Reader::MalformedPDFError)
  end

end

describe PDF::Reader::Buffer, "read method" do
  include BufferHelper

  it "should return raw data from the underlying IO" do
    buf = parse_string("stream bbb")

    buf.token.should eql("stream")
    buf.read(3).should eql("bbb")
  end

  it "should return raw data from the underlying IO" do
    buf = parse_string("stream\n\nbbb")

    buf.token.should eql("stream")
    buf.read(4).should eql("\nbbb")
  end

  it "should return raw data from the underlying IO and skip LF/CR bytes" do
    buf = parse_string("stream\n\nbbb")

    buf.token.should eql("stream")
    buf.read(3, :skip_eol => true).should eql("bbb")
  end
end
