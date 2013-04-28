# coding: utf-8

describe Marron::Buffer, "token method" do
  include BufferHelper
  include EncodingHelper

  context "when there's no IO left" do
    it "returns nil" do
      buf = parse_string("aaa")

      buf.token
      expect(buf.token).to be_nil
    end
  end

  context "a simple token" do
    it "tokenises correctly" do
      buf = parse_string("aaa")

      expect(buf.token).to eql("aaa")
      expect(buf.token).to be_nil
    end
  end

  context "a simple token" do
    it "tokenises correctly" do
      buf = parse_string("1.0")

      expect(buf.token).to eql("1.0")
      expect(buf.token).to be_nil
    end
  end

  context "two simple tokens" do
    it "tokenise correctly" do
      buf = parse_string("aaa 1.0")

      expect(buf.token).to eql("aaa")
      expect(buf.token).to eql("1.0")
      expect(buf.token).to be_nil
    end
  end

  context "opening delimiters" do
    it "tokenise correctly" do
      buf = parse_string("<[{/(")

      expect(buf.token).to eql("<")
      expect(buf.token).to eql(">") # auto adds closing hex string delim
      expect(buf.token).to eql("[")
      expect(buf.token).to eql("{")
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("")  # auto adds empty name token
      expect(buf.token).to eql("(")
      expect(buf.token).to eql(")") # auto adds closing literal string delim
      expect(buf.token).to be_nil
    end
  end

  context "opening delimiters" do
    it "tokenise correctly" do
      buf = parse_string(")>]}")

      expect(buf.token).to eql(")")
      expect(buf.token).to eql(">")
      expect(buf.token).to eql("]")
      expect(buf.token).to eql("}")
      expect(buf.token).to be_nil
    end
  end

  context "hash delimiters" do
    it "tokenise correctly" do
      buf = parse_string("<<aaa>>")

      expect(buf.token).to eql("<<")
      expect(buf.token).to eql("aaa")
      expect(buf.token).to eql(">>")
      expect(buf.token).to be_nil
    end
  end

  context "simple tokens with delimiters" do
    it "tokenise correctly" do
      buf = parse_string("<aaa><bbb>")

      expect(buf.token).to eql("<")
      expect(buf.token).to eql("aaa")
      expect(buf.token).to eql(">")
      expect(buf.token).to eql("<")
      expect(buf.token).to eql("bbb")
      expect(buf.token).to eql(">")
      expect(buf.token).to be_nil
    end
  end

  context "two name tokens" do
    it "tokenise correctly" do
      buf = parse_string("/Type/Pages")

      expect(buf.token).to eql("/")
      expect(buf.token).to eql("Type")
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("Pages")
      expect(buf.token).to be_nil
    end
  end

  context "two empty name tokens" do
    it "tokenise correctly" do
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
  end

  context "dict with an empty name" do
    it "tokenises correctly" do
      buf = parse_string("<</V/>>")

      expect(buf.token).to eql("<<")
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("V")
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("")
      expect(buf.token).to eql(">>")
      expect(buf.token).to be_nil
    end
  end

  context "dict" do
    it "tokenises correctly" do
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
  end

  context "string without a %" do
    it "tokenises correctly" do
      buf = parse_string("(James)")
      expect(buf.token).to eql("(")
      expect(buf.token).to eql("James")
      expect(buf.token).to eql(")")
    end
  end

  context "literal string with a %" do
    it "tokenises correctly" do
      buf = parse_string("(James%Healy)")
      expect(buf.token).to eql("(")
      expect(buf.token).to eql("James%Healy")
      expect(buf.token).to eql(")")
    end
  end

  context "hex string with a space" do
    it "tokenises correctly" do
      buf = parse_string("<AA BB>")
      expect(buf.token).to eql("<")
      expect(buf.token).to eql("AABB")
      expect(buf.token).to eql(">")
    end
  end

  context "string with comments" do
    it "tokenises correctly" do
      buf = parse_string("(James%Healy) % this is a comment\n(")
      expect(buf.token).to eql("(")
      expect(buf.token).to eql("James%Healy")
      expect(buf.token).to eql(")")
      expect(buf.token).to eql("(")
    end
  end

  context "string with comments" do
    it "tokenises correctly" do
      buf = parse_string("James % this is a comment")
      expect(buf.token).to eql("James")
      expect(buf.token).to be_nil
    end
  end

  context "string with an escaped, unbalanced param correctly" do
    it "tokenises correctly" do
      buf = parse_string("(James \\(Code Monkey)")
      expect(buf.token).to eql("(")
      expect(buf.token).to eql("James \\(Code Monkey")
      expect(buf.token).to eql(")")
    end
  end

  context "indirect reference" do
    it "tokenises correctly" do
      buf = parse_string("aaa 1 0 R bbb")

      expect(buf.token).to eql("aaa")
      expect(buf.token).to be_a_kind_of(Marron::Reference)
      expect(buf.token).to eql("bbb")
      expect(buf.token).to be_nil
    end
  end

  context "two indirect references" do
    it "tokenises correctly" do
      buf = parse_string("1 0 R 2 0 R")

      expect(buf.token).to be_a_kind_of(Marron::Reference)
      expect(buf.token).to be_a_kind_of(Marron::Reference)
      expect(buf.token).to be_nil
    end
  end

  context "initialize with a specific position" do
    it "tokenises correctly" do
      str = "aaa bbb ccc"
      buf = Marron::Buffer.new(StringIO.new(str), :seek => 4)

      expect(buf.token).to eql("bbb")
      expect(buf.token).to eql("ccc")
      expect(buf.token).to be_nil
    end
  end

  context "initialize with a specific position" do
    it "tokenises correctly" do
      str = "aaa bbb ccc"
      buf = Marron::Buffer.new(StringIO.new(str), :seek => 5)

      expect(buf.token).to eql("bb")
      expect(buf.token).to eql("ccc")
      expect(buf.token).to be_nil
    end
  end

  context "simple literal string" do
    it "tokenises correctly" do
      buf = parse_string("(aaa)")

      expect(buf.token).to eql("(")
      expect(buf.token).to eql("aaa")
      expect(buf.token).to eql(")")
      expect(buf.token).to be_nil
    end
  end

  context "empty literal string" do
    it "tokenises correctly" do
      buf = parse_string("()")

      expect(buf.token).to eql("(")
      expect(buf.token).to eql(")")
      expect(buf.token).to be_nil
    end
  end

  context "literal string with spaces" do
    it "tokenises correctly" do
      buf = parse_string("(aaa bbb)")

      expect(buf.token).to eql("(")
      expect(buf.token).to eql("aaa bbb")
      expect(buf.token).to eql(")")
      expect(buf.token).to be_nil
    end
  end

  context "literal string with nested brackets" do
    it "tokenises correctly" do
      buf = parse_string("(aaa (bbb))")

      expect(buf.token).to eql("(")
      expect(buf.token).to eql("aaa (bbb)")
      expect(buf.token).to eql(")")
      expect(buf.token).to be_nil
    end
  end

  context "literal string with escaped slash followed by a closing brace" do
    it "tokenises correctly" do
      buf = parse_string("(aaa\x5C\x5C)")

      expect(buf.token).to eql("(")
      expect(buf.token).to eql("aaa\x5C\x5C")
      expect(buf.token).to eql(")")
      expect(buf.token).to be_nil
    end
  end

  context "literal string with three slashes followed by a closing brace" do
    it "tokenises correctly" do
      buf = parse_string("(aaa\x5C\x5C\x5C))")

      expect(buf.token).to eql("(")
      expect(buf.token).to eql("aaa\x5C\x5C\x5C)")
      expect(buf.token).to eql(")")
      expect(buf.token).to be_nil
    end
  end

  context "dictionary with embedded hex string" do
    it "tokenises correctly" do
      buf = parse_string("<< /X <48656C6C6F> >>")
      expect(buf.token).to eql("<<")
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("X")
      expect(buf.token).to eql("<")
      expect(buf.token).to eql("48656C6C6F")
      expect(buf.token).to eql(">")
      expect(buf.token).to eql(">>")
    end
  end

  context "dictionary with embedded hex string" do
    it "tokenises correctly" do
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
  end

  context "dictionary with an indirect reference" do
    it "tokenises correctly" do
      buf = parse_string("<< /X 10 0 R >>")
      expect(buf.token).to eql("<<")
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("X")
      expect(buf.token).to be_a_kind_of(Marron::Reference)
      expect(buf.token).to eql(">>")
    end
  end

  context "dictionary with an indirect reference and more than 10 tokens" do
    it "tokenises correctly" do
      buf = parse_string("<< /X 10 0 R /Y 11 0 R /Z 12 0 R >>")
      expect(buf.token).to eql("<<")
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("X")
      expect(buf.token).to be_a_kind_of(Marron::Reference)
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("Y")
      expect(buf.token).to be_a_kind_of(Marron::Reference)
      expect(buf.token).to eql("/")
      expect(buf.token).to eql("Z")
      expect(buf.token).to be_a_kind_of(Marron::Reference)
      expect(buf.token).to eql(">>")
    end
  end

  context "position after available after each token" do
    it "updates" do
      buf = parse_string("aaa bbb")

      expect(buf.pos).to eql(0)
      buf.token
      expect(buf.pos).to eql(7)
    end
  end

  context "when the underlying IO pos changes on us" do
    it "the buffer pos remains accurate" do
      io = StringIO.new("aaa bbb")
      buf = Marron::Buffer.new(io)

      expect(buf.pos).to eql(0)
      buf.token
      buf.token
      expect(buf.pos).to eql(7)
      io.seek(0)

      expect(buf.token).to be_nil
      expect(buf.pos).to eql(7)
    end
  end

  context "inline image when inside a content stream" do
    it "tokenises correctly" do
      io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0\xF0\xF0 EI"))
      buf = Marron::Buffer.new(io, :content_stream => true)

      expect(buf.pos).to eql(0)
      expect(buf.token).to eql("BI")
      expect(buf.token).to eql("ID")
      expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0\xF0\xF0"))
      expect(buf.token).to eql("EI")
    end
  end

  context "inline image" do
    context "outside a content stream" do
      it "tokenises correctly" do
        io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0\xF0\xF0 EI"))
        buf = Marron::Buffer.new(io, :content_stream => false)

        expect(buf.pos).to eql(0)
        expect(buf.token).to eql("BI")
        expect(buf.token).to eql("ID")
        expect(buf.token).to eql("aaa")
        expect(buf.token).to eql("bbb")
        expect(buf.token).to eql("ccc")
        expect(buf.token).to eql(binary_string("\xF0\xF0\xF0"))
        expect(buf.token).to eql("EI")
      end
    end
  end

  context "inline image that contains the letters 'EI' within the image data" do
    context "inside a content stream" do
      it "tokenises correctly" do
        io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0EI\xF0 EI"))
        buf = Marron::Buffer.new(io, :content_stream => true)

        expect(buf.pos).to eql(0)
        expect(buf.token).to eql("BI")
        expect(buf.token).to eql("ID")
        expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0EI\xF0"))
        expect(buf.token).to eql("EI")
      end
    end
  end

  context "inline image that contains the letters 'EI' within the image data" do
    context "inside a content stream" do
      it "tokenises correctly" do
        io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0EI\xF0\nEI"))
        buf = Marron::Buffer.new(io, :content_stream => true)

        expect(buf.pos).to eql(0)
        expect(buf.token).to eql("BI")
        expect(buf.token).to eql("ID")
        expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0EI\xF0"))
        expect(buf.token).to eql("EI")
      end
    end
  end

  context "inline image with no whitespace before the letters 'EI'" do
    context "inside a content stream" do
      it "tokenises correctly" do
        io = StringIO.new(binary_string("BI ID aaa bbb ccc \xF0\xF0\xF0\x00EI"))
        buf = Marron::Buffer.new(io, :content_stream => true)

        expect(buf.pos).to eql(0)
        expect(buf.token).to eql("BI")
        expect(buf.token).to eql("ID")
        expect(buf.token).to eql(binary_string("aaa bbb ccc \xF0\xF0\xF0\x00"))
        expect(buf.token).to eql("EI")
      end
    end
  end

  context "dict that has ID as a key" do
    it "tokenises correctly" do
      io = StringIO.new("<</ID /S1 >> BDC")
      buf = Marron::Buffer.new(io, :content_stream => true)

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
end

describe Marron::Buffer, "empty? method" do
  include BufferHelper

  context "with remaining tokens" do
    it "is false" do
      buf = parse_string("aaa")

      expect(buf.empty?).to be_falsey
    end
  end

  context "with no remaining tokens" do
    it "is true" do
      buf = parse_string("aaa")

      expect(buf.empty?).to be_falsey
      buf.token
      expect(buf.empty?).to be_truthy
    end
  end
end

describe Marron::Buffer, "find_first_xref_offset method" do

  context "cairo-basic.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("cairo-basic"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(9243)
    end
  end

  context "cairo-unicode.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("cairo-unicode"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(136174)
    end
  end

  context "prince1.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("prince1"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(678715)
    end
  end

  context "prince2.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("prince2"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(941440)
    end
  end

  context "pdfwriter-manual.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("pdfwriter-manual"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(275320)
    end
  end

  context "pdf-distiller.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("pdf-distiller"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(173)
    end
  end

  context "pdflatex.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("pdflatex"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(152898)
    end
  end

  context "openoffice-2.2.pdf" do
    it "finds the first xref offset" do
      @file = File.new(pdf_spec_file("openoffice-2.2"))
      @buffer = Marron::Buffer.new(@file)

      expect(@buffer.find_first_xref_offset).to eql(36961)
    end
  end

  context "when buffer doesn't contain an EOF marker" do
    it "raises an exception" do
      @file = File.new(pdf_spec_file("no_eof"))
      @buffer = Marron::Buffer.new(@file)

      expect { @buffer.find_first_xref_offset }.to raise_error(Marron::MalformedPDFError)
    end
  end

  context "extended_eof.pdf (bytes after the EOF marker" do
    it "finds the first xref offset" do
      file   = File.new pdf_spec_file("extended_eof")
      buffer = Marron::Buffer.new file

      expect(buffer.find_first_xref_offset).to eql(145)
    end
  end
end

describe Marron::Buffer, "read method" do
  include BufferHelper

  context "with a single line buffer" do
    it "returns raw data from the underlying IO" do
      buf = parse_string("stream bbb")

      expect(buf.token).to eql("stream")
      expect(buf.read(3)).to eql("bbb")
    end
  end

  context "with a multi-line buffer (two \\n)" do
    context "without :skip_eol" do
      it "returns raw data from the underlying IO" do
        buf = parse_string("stream\n\nbbb")

        expect(buf.token).to eql("stream")
        expect(buf.read(4)).to eql("\nbbb")
      end
    end
    context "with :skip_eol" do
      it "returns raw data from the underlying IO" do
        buf = parse_string("stream\n\nbbb")

        expect(buf.token).to eql("stream")
        expect(buf.read(3, :skip_eol => true)).to eql("\nbb")
      end
    end
  end

  context "with a multi-line buffer (single \\n)" do
    context "without :skip_eol" do
      it "returns raw data from the underlying IO" do
        buf = parse_string("stream\nbbb")

        expect(buf.token).to eql("stream")
        expect(buf.read(4)).to eql("bbb")
      end
    end
    context "with :skip_eol" do
      it "returns raw data from the underlying IO" do
        buf = parse_string("stream\nbbb")

        expect(buf.token).to eql("stream")
        expect(buf.read(3, :skip_eol => true)).to eql("bbb")
      end
    end
  end

  context "with a multi-line buffer (three \\n)" do
    context "without :skip_eol" do
      it "returns raw data from the underlying IO"
    end
    context "with :skip_eol" do
      it "returns raw data from the underlying IO" do
        buf = parse_string("stream\n\n\nbbb")

        expect(buf.token).to eql("stream")
        expect(buf.read(5, :skip_eol => true)).to eql("\n\nbbb")
      end
    end
  end

  context "with a multi-line buffer (\\r\\n)" do
    context "without :skip_eol" do
      it "returns raw data from the underlying IO"
    end
    context "with :skip_eol" do
      it "returns raw data from the underlying IO" do
        buf = parse_string("stream\r\nbbb")

        expect(buf.token).to eql("stream")
        expect(buf.read(3, :skip_eol => true)).to eql("bbb")
      end
    end
  end
end
