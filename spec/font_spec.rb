# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Font do

  it "should select a sensible encoding when set to a symbol font" do
    f = PDF::Reader::Font.new
    f.basefont = "Arial"
    f.encoding.should be_nil

    f.basefont = "Symbol"
    f.encoding.should be_a_kind_of(PDF::Reader::Encoding)

    f.basefont = "ZapfDingbats"
    f.encoding.should be_a_kind_of(PDF::Reader::Encoding)
  end

  it "should correctly attempt to convert various strings to utf-8" do
    f = PDF::Reader::Font.new
    # TODO: create a mock encoding object and ensure to_utf8 is called on it
  end

  it "should return the same type when to_utf8 is called" do
    f = PDF::Reader::Font.new
    f.to_utf8("abc").should be_a_kind_of(String)
    f.to_utf8(["abc"]).should be_a_kind_of(Array)
    f.to_utf8(123).should be_a_kind_of(Numeric)
  end

  it "should use an encoding of StandardEncoding if none has been specified" do
    f = PDF::Reader::Font.new
    str = "abc\xA8"
    f.to_utf8(str).should eql("abc\xC2\xA4")
  end

  it "should correctly store the font BaseFont" do
    f = PDF::Reader::Font.new
    f.basefont = :Helvetica
    f.basefont.should eql(:Helvetica)
  end

end
