# coding: utf-8

describe Marron::Filter do

  describe "#with" do
    context "when passed :ASCII85Decode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:ASCII85Decode)).to be_a(Marron::Filter::Ascii85)
      end
    end

    context "when passed :ASCIIHexDecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:ASCIIHexDecode)).to be_a(Marron::Filter::AsciiHex)
      end
    end

    context "when passed :CCITTFaxDecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:CCITTFaxDecode)).to be_a(Marron::Filter::Null)
      end
    end

    context "when passed :DCTDecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:DCTDecode)).to be_a(Marron::Filter::Null)
      end
    end

    context "when passed :ASCII85Decode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:ASCII85Decode)).to be_a(Marron::Filter::Ascii85)
      end
    end

    context "when passed :FlateDecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:FlateDecode)).to be_a(Marron::Filter::Flate)
      end
    end

    context "when passed :JBIG2ecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:JBIG2Decode)).to be_a(Marron::Filter::Null)
      end
    end

    context "when passed :JPXDecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:JPXDecode)).to be_a(Marron::Filter::Null)
      end
    end

    context "when passed :LZWDecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:LZWDecode)).to be_a(Marron::Filter::Lzw)
      end
    end

    context "when passed :RunLengthDecode" do
      it "returns the appropriate class" do
        expect(Marron::Filter.with(:RunLengthDecode)).to be_a(Marron::Filter::RunLength)
      end
    end

    context "when passed an unrecognised filter" do
      it "raises an exception" do
        expect {
          Marron::Filter.with(:FooDecode)
        }.to raise_error(Marron::UnsupportedFeatureError)
      end
    end
  end
end
