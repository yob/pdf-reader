# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::GlyphHash, "#name_to_unicode" do

  it "should correctly map a standard glyph name to unicode" do
    map = PDF::Reader::GlyphHash.new
    map.name_to_unicode(:a).should eql(0x0061)
    map.name_to_unicode(:e).should eql(0x0065)
    map.name_to_unicode(:A).should eql(0x0041)
    map.name_to_unicode(:holam).should eql(0x05B9)
    map.name_to_unicode(:zukatakana).should eql(0x30BA)
  end

  it "should correctly map a glyph name with underscores to unicode" do
    map = PDF::Reader::GlyphHash.new
    map.name_to_unicode(:f_i).should eql(map.name_to_unicode(:fi))
  end

  it "should correctly map a uniHHHH glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map.name_to_unicode(:uni0032).should eql(0x0032)
    map.name_to_unicode(:uni1234).should eql(0x1234)
  end

  it "should correctly map a uHHHH glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map.name_to_unicode(:u0032).should   eql(0x0032)
    map.name_to_unicode(:u1234).should   eql(0x1234)
    map.name_to_unicode(:u12345).should  eql(0x12345)
    map.name_to_unicode(:u123456).should eql(0x123456)
  end

  it "should correctly map a Ann glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map.name_to_unicode(:A65).should     eql(65)
    map.name_to_unicode(:g3).should      eql(3)
    map.name_to_unicode(:g65).should     eql(65)
    map.name_to_unicode(:G65).should     eql(65)
    map.name_to_unicode(:G655).should    eql(655)
    map.name_to_unicode(:G6555).should   eql(6555)
    map.name_to_unicode(:G20000).should  eql(20000)
  end

  it "should correctly map a AAnn glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    map.name_to_unicode(:AA65).should     eql(65)
    map.name_to_unicode(:gg65).should     eql(65)
    map.name_to_unicode(:GG65).should     eql(65)
    map.name_to_unicode(:GG655).should    eql(655)
    map.name_to_unicode(:GG6555).should   eql(6555)
    map.name_to_unicode(:GG20000).should eql(20000)
  end

end

describe PDF::Reader::GlyphHash, "#unicode_to_name" do

  it "should correctly map a standard glyph name to unicode" do
    map = PDF::Reader::GlyphHash.new
    map.unicode_to_name(0x0061).should eql([:a])
    map.unicode_to_name(0x0065).should eql([:e])
    map.unicode_to_name(0x0041).should eql([:A])
    map.unicode_to_name(0x05B9).should eql(
      [:afii57806, :holam, :holam19, :holam26,
      :holam32, :holamhebrew, :holamnarrowhebrew,
      :holamquarterhebrew, :holamwidehebrew]
    )
    map.unicode_to_name(0x20AC).should eql([:Euro, :euro])
    map.unicode_to_name(0x30BA).should eql([:zukatakana])
  end
end
