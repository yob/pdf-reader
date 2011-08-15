# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::GlyphHash do

  it "should correctly map a standard glyph name to unicode" do
    map = PDF::Reader::GlyphHash.new
    map[:a].should eql(0x0061)
    map[:e].should eql(0x0065)
    map[:A].should eql(0x0041)
    map[:holam].should eql(0x05B9)
    map[:zukatakana].should eql(0x30BA)
  end

  it "should correctly map a uniHHHH glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map[:uni0032].should eql(0x0032)
    map[:uni1234].should eql(0x1234)
  end

  it "should correctly map a uHHHH glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map[:u0032].should   eql(0x0032)
    map[:u1234].should   eql(0x1234)
    map[:u12345].should  eql(0x12345)
    map[:u123456].should eql(0x123456)
  end

  it "should correctly map a Ann glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map[:A65].should   eql(65)
    map[:g65].should   eql(65)
    map[:G65].should   eql(65)
  end

  it "should correctly map a AAnn glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map[:AA65].should   eql(65)
    map[:gg65].should   eql(65)
    map[:GG65].should   eql(65)
  end

end
