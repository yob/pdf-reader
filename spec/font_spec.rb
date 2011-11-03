# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Font do

  let(:object_hash) { PDF::Reader::ObjectHash.allocate }
  let(:font) { PDF::Reader::Font.new(object_hash, {}) }

  it "should select a sensible encoding when set to a symbol font" do
    font.basefont = "Arial"
    font.encoding.should be_nil

    font.basefont = "Symbol"
    font.encoding.should be_a_kind_of(PDF::Reader::Encoding)

    font.basefont = "ZapfDingbats"
    font.encoding.should be_a_kind_of(PDF::Reader::Encoding)
  end

  it "should correctly attempt to convert strings to utf-8" do
    encoding = stub
    font.encoding = encoding
    encoding.should_receive(:to_utf8).with("hello", font.tounicode)
    font.to_utf8("hello")
  end

  it "should correctly attempt to convert strings in arrays to utf-8" do
    encoding = stub
    font.encoding = encoding
    encoding.should_receive(:to_utf8).with("hello", font.tounicode)
    encoding.should_receive(:to_utf8).with("howdy", font.tounicode)
    font.to_utf8(["hello", 1, "howdy"])
  end

  it "should return the same type when to_utf8 is called" do
    font.to_utf8("abc").should be_a_kind_of(String)
    font.to_utf8(["abc"]).should be_a_kind_of(Array)
    font.to_utf8(123).should be_a_kind_of(Numeric)
  end

  it "should use an encoding of StandardEncoding if none has been specified" do
    str = "abc\xA8"
    font.to_utf8(str).should eql("abc\xC2\xA4")
  end

  it "should correctly store the font BaseFont" do
    font.basefont = :Helvetica
    font.basefont.should eql(:Helvetica)
  end

end
