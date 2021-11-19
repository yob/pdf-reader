# typed: false
# coding: utf-8

describe PDF::Reader::Font do

  let(:object_hash) { PDF::Reader::ObjectHash.allocate }

  describe "to_utf8()" do
    context "with no ToUnicode CMap" do
      let(:font) { PDF::Reader::Font.new(object_hash, {}) }

      it "delegates to an Encoding object to convert strings to utf-8" do
        encoding = double
        font.encoding = encoding
        expect(encoding).to receive(:to_utf8).with("hello")
        font.to_utf8("hello")
      end

      it "delegates to an Encoding object to convert arrays of strings to utf-8" do
        encoding = double
        font.encoding = encoding
        expect(encoding).to receive(:to_utf8).with("hello")
        expect(encoding).to receive(:to_utf8).with("howdy")
        font.to_utf8(["hello", "howdy"])
      end

      it "returns the same type when to_utf8 is called with a string or array" do
        expect(font.to_utf8("abc")).to be_a_kind_of(String)
        expect(font.to_utf8(["abc"])).to be_a_kind_of(Array)
      end

      it "converts integers to a utf-8 string" do
        expect(font.to_utf8(123)).to be_a_kind_of(String)
      end

      it "uses an encoding of StandardEncoding if none has been specified" do
        str = "abc\xA8"
        expect(font.to_utf8(str)).to eql("abc\xC2\xA4")
      end
    end

    context "with a ToUnicode CMap" do
      let(:font) { PDF::Reader::Font.new(object_hash, {}) }

      it "delegates to a CMap object to convert strings to utf-8" do
        cmap = double
        expect(cmap).to receive(:decode).with(104).and_return(104)
        expect(cmap).to receive(:decode).with(101).and_return(104)
        expect(cmap).to receive(:decode).with(108).and_return(104)
        expect(cmap).to receive(:decode).with(108).and_return(104)
        expect(cmap).to receive(:decode).with(111).and_return(104)
        font.tounicode = cmap

        font.to_utf8("hello")
      end

      it "doesn't delegate to an Encoding object to convert strings to utf-8" do
        encoding = double
        expect(encoding).not_to receive(:to_utf8)
        expect(encoding).to receive(:unpack).and_return("C*")
        font.encoding = encoding
        cmap = double
        expect(cmap).to receive(:decode).exactly(5).times.and_return(104)
        font.tounicode = cmap

        font.to_utf8("hello")
      end

    end
  end
  describe "unpack()" do
    context "with a WinAnsi encoded font" do
      let(:raw)  do
        {
          :Encoding  => :WinAnsiEncoding,
          :Type      => :Font
        }
      end
      let(:font) { PDF::Reader::Font.new(object_hash, raw) }

      it "unpacks a binary string into ints" do
        expect(font.unpack("\x41\x42")).to eq([65,66])
      end
    end
  end

  describe "glyph_width()" do
    context "with a FirstChar of 1" do
      let(:raw)  do
        {
          :Encoding  => :WinAnsiEncoding,
          :Type      => :Font,
          :FirstChar => 1,
          :Widths    => [100, 200, 300, 400]
        }
      end
      let(:font) { PDF::Reader::Font.new(object_hash, raw) }

      it "returns the width for a glyph" do
        expect(font.glyph_width(2)).to eq(200)
      end

      it "returns 0 for an unknown glyph" do
        expect(font.glyph_width(10)).to eq(0)
      end
    end

    context "with a FirstChar of 5" do
      let(:raw)  do
        {
          :Encoding  => :WinAnsiEncoding,
          :Type      => :Font,
          :FirstChar => 5,
          :Widths    => [100, 200, 300, 400]
        }
      end
      let(:font) { PDF::Reader::Font.new(object_hash, raw) }

      it "returns the width for a glyph" do
        expect(font.glyph_width(7)).to eq(300)
      end

      it "returns 0 for an unknown glyph" do
        expect(font.glyph_width(20)).to eq(0)
      end
    end
  end

end
