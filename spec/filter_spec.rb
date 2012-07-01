# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Filter do

  describe "#with" do
    context "when passed :ASCII85Decode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:ASCII85Decode).should be_a(PDF::Reader::Filter::Ascii85)
      end
    end

    context "when passed :ASCIIHexDecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:ASCIIHexDecode).should be_a(PDF::Reader::Filter::AsciiHex)
      end
    end

    context "when passed :CCITTFaxDecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:CCITTFaxDecode).should be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :DCTDecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:DCTDecode).should be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :ASCII85Decode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:ASCII85Decode).should be_a(PDF::Reader::Filter::Ascii85)
      end
    end

    context "when passed :FlateDecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:FlateDecode).should be_a(PDF::Reader::Filter::Flate)
      end
    end

    context "when passed :JBIG2ecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:JBIG2Decode).should be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :JPXDecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:JPXDecode).should be_a(PDF::Reader::Filter::Null)
      end
    end

    context "when passed :LZWDecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:LZWDecode).should be_a(PDF::Reader::Filter::Lzw)
      end
    end

    context "when passed :RunLengthDecode" do
      it "should return the appropriate class" do
        PDF::Reader::Filter.with(:RunLengthDecode).should be_a(PDF::Reader::Filter::RunLength)
      end
    end

    context "when passed an unrecognised filter" do
      it "should raise an exception" do
        lambda {
          PDF::Reader::Filter.with(:FooDecode)
        }.should raise_error(PDF::Reader::UnsupportedFeatureError)
      end
    end
  end
end
