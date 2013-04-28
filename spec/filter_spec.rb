# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe Marron::Filter do

  describe "#with" do
    context "when passed :ASCII85Decode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:ASCII85Decode).should be_a(Marron::Filter::Ascii85)
      end
    end

    context "when passed :ASCIIHexDecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:ASCIIHexDecode).should be_a(Marron::Filter::AsciiHex)
      end
    end

    context "when passed :CCITTFaxDecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:CCITTFaxDecode).should be_a(Marron::Filter::Null)
      end
    end

    context "when passed :DCTDecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:DCTDecode).should be_a(Marron::Filter::Null)
      end
    end

    context "when passed :ASCII85Decode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:ASCII85Decode).should be_a(Marron::Filter::Ascii85)
      end
    end

    context "when passed :FlateDecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:FlateDecode).should be_a(Marron::Filter::Flate)
      end
    end

    context "when passed :JBIG2ecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:JBIG2Decode).should be_a(Marron::Filter::Null)
      end
    end

    context "when passed :JPXDecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:JPXDecode).should be_a(Marron::Filter::Null)
      end
    end

    context "when passed :LZWDecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:LZWDecode).should be_a(Marron::Filter::Lzw)
      end
    end

    context "when passed :RunLengthDecode" do
      it "should return the appropriate class" do
        Marron::Filter.with(:RunLengthDecode).should be_a(Marron::Filter::RunLength)
      end
    end

    context "when passed an unrecognised filter" do
      it "should raise an exception" do
        lambda {
          Marron::Filter.with(:FooDecode)
        }.should raise_error(Marron::UnsupportedFeatureError)
      end
    end
  end
end
