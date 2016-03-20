# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Buffer, "token method" do
  include BufferHelper
  include EncodingHelper

  it "should return nil when there's no IO left" do
    buf = parse_string("aaa")

    buf.token
    expect(buf.token).to be_nil
  end

  it "should correctly return a simple token - 1" do
    buf = parse_string("aaa")

    expect(buf.token).to eql("aaa")
    expect(buf.token).to be_nil
  end

  it "should correctly return a simple token - 2" do
    buf = parse_string("1.0")

    expect(buf.token).to eql("1.0")
    expect(buf.token).to be_nil
  end

  it "should correctly return two simple tokens" do
    buf = parse_string("aaa 1.0")

    expect(buf.token).to eql("aaa")
    expect(buf.token).to eql("1.0")
    expect(buf.token).to be_nil
  end

  it "should correctly tokenise opening delimiters" do
    buf = parse_string("<[{/(")

    expect(buf.token).to eql("<")
    expect(buf.token).to eql(">") # auto adds closing hex string delim
    expect(buf.token).to eql("[")
    expect(buf.token).to eql("{")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("(")
    expect(buf.token).to eql(")") # auto adds closing literal string delim
    expect(buf.token).to be_nil
  end

  it "should correctly tokenise closing delimiters" do
    buf = parse_string(")>]}")

    expect(buf.token).to eql(")")
    expect(buf.token).to eql(">")
    expect(buf.token).to eql("]")
    expect(buf.token).to eql("}")
    expect(buf.token).to be_nil
  end

  it "should correctly tokenise hash delimiters" do
    buf = parse_string("<<aaa>>")

    expect(buf.token).to eql("<<")
    expect(buf.token).to eql("aaa")
    expect(buf.token).to eql(">>")
    expect(buf.token).to be_nil
  end

  it "should correctly return simple tokens with delimiters" do
    buf = parse_string("<aaa><bbb>")

    expect(buf.token).to eql("<")
    expect(buf.token).to eql("aaa")
    expect(buf.token).to eql(">")
    expect(buf.token).to eql("<")
    expect(buf.token).to eql("bbb")
    expect(buf.token).to eql(">")
    expect(buf.token).to be_nil
  end

  it "should correctly return two name tokens" do
    buf = parse_string("/Type/Pages")

    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Type")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Pages")
    expect(buf.token).to be_nil
  end

  it "should correctly return two empty name tokens" do
    buf = parse_string("/ /")

    expect(buf.token).to eql("/")
    expect(buf.token).to eql("")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("")
    expect(buf.token).to be_nil

    buf = parse_string("/\n/")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("")
    expect(buf.token).to be_nil
  end

  it "should tokenise a dict correctly" do
    buf = parse_string("/Registry (Adobe) /Ordering (Japan1) /Supplement")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Registry")
    expect(buf.token).to eql("(")
    expect(buf.token).to eql("Adobe")
    expect(buf.token).to eql(")")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Ordering")
    expect(buf.token).to eql("(")
    expect(buf.token).to eql("Japan1")
    expect(buf.token).to eql(")")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Supplement")
  end

  it "should tokenise a string without a % correctly" do
    buf = parse_string("(James)")
    expect(buf.token).to eql("(")
    expect(buf.token).to eql("James")
    expect(buf.token).to eql(")")
  end

  it "should tokenise a literal string with a % correctly" do
    buf = parse_string("(James%Healy)")
    expect(buf.token).to eql("(")
    expect(buf.token).to eql("James%Healy")
    expect(buf.token).to eql(")")
  end

  it "should tokenise a hex string with a space correctly" do
    buf = parse_string("<AA BB>")
    expect(buf.token).to eql("<")
    expect(buf.token).to eql("AABB")
    expect(buf.token).to eql(">")
  end

  it "should tokenise a string with comments correctly" do
    buf = parse_string("(James%Healy) % this is a comment\n(")
    expect(buf.token).to eql("(")
    expect(buf.token).to eql("James%Healy")
    expect(buf.token).to eql(")")
    expect(buf.token).to eql("(")
  end

  it "should tokenise a string with comments correctly" do
    buf = parse_string("James % this is a comment")
    expect(buf.token).to eql("James")
    expect(buf.token).to be_nil
  end

  it "should tokenise a string with an escaped, unbalanced param correctly" do
    buf = parse_string("(James \\(Code Monkey)")
    expect(buf.token).to eql("(")
    expect(buf.token).to eql("James \\(Code Monkey")
    expect(buf.token).to eql(")")
  end

  it "should correctly return an indirect reference" do
    buf = parse_string("aaa 1 0 R bbb")

    expect(buf.token).to eql("aaa")
    expect(buf.token).to be_a_kind_of(PDF::Reader::Reference)
    expect(buf.token).to eql("bbb")
    expect(buf.token).to be_nil
  end

  it "should correctly return two indirect references" do
    buf = parse_string("1 0 R 2 0 R")

    expect(buf.token).to be_a_kind_of(PDF::Reader::Reference)
    expect(buf.token).to be_a_kind_of(PDF::Reader::Reference)
    expect(buf.token).to be_nil
  end

  it "should correctly seek to a particular byte of the IO - 1" do
    str = "aaa bbb ccc"
    buf = PDF::Reader::Buffer.new(StringIO.new(str), :seek => 4)

    expect(buf.token).to eql("bbb")
    expect(buf.token).to eql("ccc")
    expect(buf.token).to be_nil
  end

  it "should correctly seek to a particular byte of the IO - 2" do
    str = "aaa bbb ccc"
    buf = PDF::Reader::Buffer.new(StringIO.new(str), :seek => 5)

    expect(buf.token).to eql("bb")
    expect(buf.token).to eql("ccc")
    expect(buf.token).to be_nil
  end

  it "should correctly return a simple literal string" do
    buf = parse_string("(aaa)")

    expect(buf.token).to eql("(")
    expect(buf.token).to eql("aaa")
    expect(buf.token).to eql(")")
    expect(buf.token).to be_nil
  end

  it "should correctly return an empty literal string" do
    buf = parse_string("()")

    expect(buf.token).to eql("(")
    expect(buf.token).to eql(")")
    expect(buf.token).to be_nil
  end

  it "should correctly return a simple literal string with spaces" do
    buf = parse_string("(aaa bbb)")

    expect(buf.token).to eql("(")
    expect(buf.token).to eql("aaa bbb")
    expect(buf.token).to eql(")")
    expect(buf.token).to be_nil
  end

  it "should correctly return a simple literal string with nested brackets" do
    buf = parse_string("(aaa (bbb))")

    expect(buf.token).to eql("(")
    expect(buf.token).to eql("aaa (bbb)")
    expect(buf.token).to eql(")")
    expect(buf.token).to be_nil
  end

  it "should correctly return a literal string with escaped slash followed by a closing brace" do
    buf = parse_string("(aaa\x5C\x5C)")

    expect(buf.token).to eql("(")
    expect(buf.token).to eql("aaa\x5C\x5C")
    expect(buf.token).to eql(")")
    expect(buf.token).to be_nil
  end

  it "should correctly return a literal string with three slashes followed by a closing brace" do
    buf = parse_string("(aaa\x5C\x5C\x5C))")

    expect(buf.token).to eql("(")
    expect(buf.token).to eql("aaa\x5C\x5C\x5C)")
    expect(buf.token).to eql(")")
    expect(buf.token).to be_nil
  end

  it "should correctly return a dictionary with embedded hex string" do
    buf = parse_string("<< /X <48656C6C6F> >>")
    expect(buf.token).to eql("<<")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("X")
    expect(buf.token).to eql("<")
    expect(buf.token).to eql("48656C6C6F")
    expect(buf.token).to eql(">")
    expect(buf.token).to eql(">>")
  end
  it "should correctly return a dictionary with embedded hex string" do
    buf = parse_string("/Span<</ActualText<FEFF0009>>> BDC")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Span")
    expect(buf.token).to eql("<<")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("ActualText")
    expect(buf.token).to eql("<")
    expect(buf.token).to eql("FEFF0009")
    expect(buf.token).to eql(">")
    expect(buf.token).to eql(">>")
    expect(buf.token).to eql("BDC")
  end

  it "should correctly return a dictionary with an indirect reference" do
    buf = parse_string("<< /X 10 0 R >>")
    expect(buf.token).to eql("<<")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("X")
    expect(buf.token).to be_a_kind_of(PDF::Reader::Reference)
    expect(buf.token).to eql(">>")
  end

  it "should correctly return a dictionary with an indirect reference and more than 10 tokens" do
    buf = parse_string("<< /X 10 0 R /Y 11 0 R /Z 12 0 R >>")
    expect(buf.token).to eql("<<")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("X")
    expect(buf.token).to be_a_kind_of(PDF::Reader::Reference)
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Y")
    expect(buf.token).to be_a_kind_of(PDF::Reader::Reference)
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("Z")
    expect(buf.token).to be_a_kind_of(PDF::Reader::Reference)
    expect(buf.token).to eql(">>")
  end

  it "should record io position" do
    buf = parse_string("aaa bbb")

    expect(buf.pos).to eql(0)
    buf.token
    expect(buf.pos).to eql(7)
  end

  it "should restore io position if it's been changed on us" do
    io = StringIO.new("aaa bbb")
    buf = PDF::Reader::Buffer.new(io)

    expect(buf.pos).to eql(0)
    buf.token
    buf.token
    expect(buf.pos).to eql(7)
    io.seek(0)

    expect(buf.token).to be_nil
    expect(buf.pos).to eql(7)
  end

  it "should correctly tokenise an inline image when inside a content stream" do
    io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0\xF0\xF0 EI"))
    buf = PDF::Reader::Buffer.new(io, :content_stream => true)

    expect(buf.pos).to eql(0)
    expect(buf.token).to eql("BI")
    expect(buf.token).to eql("ID")
    expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0\xF0\xF0"))
    expect(buf.token).to eql("EI")
  end

  it "should correctly tokenise an inline image when outside a content stream" do
    io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0\xF0\xF0 EI"))
    buf = PDF::Reader::Buffer.new(io, :content_stream => false)

    expect(buf.pos).to eql(0)
    expect(buf.token).to eql("BI")
    expect(buf.token).to eql("ID")
    expect(buf.token).to eql("aaa")
    expect(buf.token).to eql("bbb")
    expect(buf.token).to eql("ccc")
    expect(buf.token).to eql(binary_string("\xF0\xF0\xF0"))
    expect(buf.token).to eql("EI")
  end

  it "should correctly tokenise an inline image that contains the letters 'EI' within the image data" do
    io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0EI\xF0 EI"))
    buf = PDF::Reader::Buffer.new(io, :content_stream => true)

    expect(buf.pos).to eql(0)
    expect(buf.token).to eql("BI")
    expect(buf.token).to eql("ID")
    expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0EI\xF0"))
    expect(buf.token).to eql("EI")
  end

  it "should correctly tokenise an inline image that contains the letters 'EI' within the image data" do
    io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0EI\xF0\nEI"))
    buf = PDF::Reader::Buffer.new(io, :content_stream => true)

    expect(buf.pos).to eql(0)
    expect(buf.token).to eql("BI")
    expect(buf.token).to eql("ID")
    expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0EI\xF0"))
    expect(buf.token).to eql("EI")
  end

  it "should correctly tokenise an inline image with no whitespace before the letters 'EI'" do
    io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0\xF0\xF0\x00EI"))
    buf = PDF::Reader::Buffer.new(io, :content_stream => true)

    expect(buf.pos).to eql(0)
    expect(buf.token).to eql("BI")
    expect(buf.token).to eql("ID")
    expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0\xF0\xF0\x00"))
    expect(buf.token).to eql("EI")
  end

  it "should correctly tokenise a hash that has ID as a key" do
    io = StringIO.new("<</ID /S1 >> BDC")
    buf = PDF::Reader::Buffer.new(io, :content_stream => true)

    expect(buf.pos).to eql(0)
    expect(buf.token).to eql("<<")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("ID")
    expect(buf.token).to eql("/")
    expect(buf.token).to eql("S1")
    expect(buf.token).to eql(">>")
    expect(buf.token).to eql("BDC")
  end
end

describe PDF::Reader::Buffer, "empty? method" do
  include BufferHelper

  it "should correctly return false if there are remaining tokens" do
    buf = parse_string("aaa")

    expect(buf.empty?).to be_falsey
  end

  it "should correctly return true if there are no remaining tokens" do
    buf = parse_string("aaa")

    expect(buf.empty?).to be_falsey
    buf.token
    expect(buf.empty?).to be_truthy
  end
end

describe PDF::Reader::Buffer, "find_first_xref_offset method" do

  it "should find the first xref offset from cairo-basic.pdf correctly" do
    @file = File.new(pdf_spec_file("cairo-basic"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(9243)
  end

  it "should find the first xref offset from cairo-unicode.pdf correctly" do
    @file = File.new(pdf_spec_file("cairo-unicode"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(136174)
  end

  it "should find the first xref offset from prince1.pdf correctly" do
    @file = File.new(pdf_spec_file("prince1"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(678715)
  end

  it "should find the first xref offset from prince2.pdf correctly" do
    @file = File.new(pdf_spec_file("prince2"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(941440)
  end

  it "should find the first xref offset from pdfwriter-manual.pdf correctly" do
    @file = File.new(pdf_spec_file("pdfwriter-manual"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(275320)
  end

  it "should find the first xref offset from pdf-distiller.pdf correctly" do
    @file = File.new(pdf_spec_file("pdf-distiller"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(173)
  end

  it "should find the first xref offset from pdflatex.pdf correctly" do
    @file = File.new(pdf_spec_file("pdflatex"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(152898)
  end

  it "should find the first xref offset from openoffice-2.2.pdf correctly" do
    @file = File.new(pdf_spec_file("openoffice-2.2"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect(@buffer.find_first_xref_offset).to eql(36961)
  end

  it "should raise an exception when buffer doesn't contain an EOF marker" do
    @file = File.new(pdf_spec_file("no_eof"))
    @buffer = PDF::Reader::Buffer.new(@file)

    expect { @buffer.find_first_xref_offset }.to raise_error(PDF::Reader::MalformedPDFError)
  end

  it "should match EOF markers when they have a suffix" do
    file   = File.new pdf_spec_file("extended_eof")
    buffer = PDF::Reader::Buffer.new file

    expect {
      buffer.find_first_xref_offset
    }.not_to raise_error
  end
end

describe PDF::Reader::Buffer, "read method" do
  include BufferHelper

  it "should return raw data from the underlying IO" do
    buf = parse_string("stream bbb")

    expect(buf.token).to eql("stream")
    expect(buf.read(3)).to eql("bbb")
  end

  it "should return raw data from the underlying IO" do
    buf = parse_string("stream\n\nbbb")

    expect(buf.token).to eql("stream")
    expect(buf.read(4)).to eql("\nbbb")
  end

  it "should return raw data from the underlying IO and skip LF/CR bytes" do
    buf = parse_string("stream\nbbb")

    expect(buf.token).to eql("stream")
    expect(buf.read(3, :skip_eol => true)).to eql("bbb")
  end

  it "should return raw data from the underlying IO and skip LF/CR bytes" do
    buf = parse_string("stream\r\nbbb")

    expect(buf.token).to eql("stream")
    expect(buf.read(3, :skip_eol => true)).to eql("bbb")
  end

  it "should return raw data from the underlying IO and skip LF/CR bytes" do
    buf = parse_string("stream\n\nbbb")

    expect(buf.token).to eql("stream")
    expect(buf.read(4, :skip_eol => true)).to eql("\nbbb")
  end

  it "should return raw data from the underlying IO and skip LF/CR bytes" do
    buf = parse_string("stream\n\n\nbbb")

    expect(buf.token).to eql("stream")
    expect(buf.read(5, :skip_eol => true)).to eql("\n\nbbb")
  end
end
