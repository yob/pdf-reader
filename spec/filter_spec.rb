# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Filter do

  describe "#with" do
    context "when passed :ASCII85Decode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:ASCII85Decode)).to be_a(PDF::Reader::Filter::Ascii85)
      end
    end

    context "when passed :ASCIIHexDecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:ASCIIHexDecode)).to be_a(PDF::Reader::Filter::AsciiHex)
      end
    end

    context "when passed :CCITTFaxDecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:CCITTFaxDecode)).to be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :DCTDecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:DCTDecode)).to be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :ASCII85Decode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:ASCII85Decode)).to be_a(PDF::Reader::Filter::Ascii85)
      end
    end

    context "when passed :FlateDecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:FlateDecode)).to be_a(PDF::Reader::Filter::Flate)
      end
    end

    context "when passed :JBIG2ecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:JBIG2Decode)).to be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :JPXDecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:JPXDecode)).to be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :LZWDecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:LZWDecode)).to be_a(PDF::Reader::Filter::Lzw)
      end
    end

    context "when passed :RunLengthDecode" do
      it "should return the appropriate class" do
        expect(PDF::Reader::Filter.with(:RunLengthDecode)).to be_a(PDF::Reader::Filter::RunLength)
      end
    end

    context "when passed an unrecognised filter" do
      it "should raise an exception" do
        expect {
          PDF::Reader::Filter.with(:FooDecode)
        }.to raise_error(PDF::Reader::UnsupportedFeatureError)
      end
    end
  end
end
