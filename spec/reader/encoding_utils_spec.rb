# typed: false
# coding: utf-8

describe PDF::Reader::EncodingUtils do
  describe ".obj_to_utf8" do
    context "with a plain ASCII string" do
      it "returns the string encoded as UTF-8" do
        result = PDF::Reader::EncodingUtils.obj_to_utf8("hello")
        expect(result).to eql("hello")
        expect(result.encoding).to eql(Encoding::UTF_8)
      end
    end

    context "with a UTF-16 encoded string (BOM present)" do
      it "converts the string to UTF-8" do
        utf16 = "\xFE\xFF\x00W\x00o\x00r\x00d"
        result = PDF::Reader::EncodingUtils.obj_to_utf8(utf16)
        expect(result).to eql("Word")
        expect(result.encoding).to eql(Encoding::UTF_8)
      end
    end

    context "with a Hash" do
      it "recursively converts string values to UTF-8" do
        input = { Creator: "Writer", Producer: "OpenOffice" }
        result = PDF::Reader::EncodingUtils.obj_to_utf8(input)
        expect(result[:Creator].encoding).to eql(Encoding::UTF_8)
        expect(result[:Producer].encoding).to eql(Encoding::UTF_8)
      end

      it "converts UTF-16 string values in a hash" do
        utf16 = "\xFE\xFF\x00W\x00o\x00r\x00d"
        result = PDF::Reader::EncodingUtils.obj_to_utf8({ Title: utf16 })
        expect(result[:Title]).to eql("Word")
        expect(result[:Title].encoding).to eql(Encoding::UTF_8)
      end
    end

    context "with an Array" do
      it "recursively converts string elements to UTF-8" do
        result = PDF::Reader::EncodingUtils.obj_to_utf8(["hello", "world"])
        result.each do |str|
          expect(str.encoding).to eql(Encoding::UTF_8)
        end
      end

      it "converts UTF-16 string elements in an array" do
        utf16 = "\xFE\xFF\x00H\x00i"
        result = PDF::Reader::EncodingUtils.obj_to_utf8([utf16])
        expect(result.first).to eql("Hi")
      end
    end

    context "with a non-string, non-collection value" do
      it "returns integers unchanged" do
        expect(PDF::Reader::EncodingUtils.obj_to_utf8(42)).to eql(42)
      end

      it "returns symbols unchanged" do
        expect(PDF::Reader::EncodingUtils.obj_to_utf8(:foo)).to eql(:foo)
      end

      it "returns nil unchanged" do
        expect(PDF::Reader::EncodingUtils.obj_to_utf8(nil)).to be_nil
      end
    end
  end

  describe ".string_to_utf8" do
    context "with a plain ASCII string" do
      it "returns the string encoded as UTF-8" do
        result = PDF::Reader::EncodingUtils.string_to_utf8("hello")
        expect(result).to eql("hello")
        expect(result.encoding).to eql(Encoding::UTF_8)
      end
    end

    context "with a UTF-16 encoded string (BOM present)" do
      it "strips the BOM and converts to UTF-8" do
        utf16 = "\xFE\xFF\x00W\x00o\x00r\x00d"
        result = PDF::Reader::EncodingUtils.string_to_utf8(utf16)
        expect(result).to eql("Word")
        expect(result.encoding).to eql(Encoding::UTF_8)
      end

      it "handles a multi-character UTF-16 string" do
        utf16 = "\xFE\xFF\x00O\x00p\x00e\x00n\x00O\x00f\x00f\x00i\x00c\x00e"
        result = PDF::Reader::EncodingUtils.string_to_utf8(utf16)
        expect(result).to eql("OpenOffice")
        expect(result.encoding).to eql(Encoding::UTF_8)
      end
    end

    context "with a string without a UTF-16 BOM" do
      it "force-encodes the string as UTF-8" do
        result = PDF::Reader::EncodingUtils.string_to_utf8("D:20101113071546")
        expect(result).to eql("D:20101113071546")
        expect(result.encoding).to eql(Encoding::UTF_8)
      end
    end
  end
end
