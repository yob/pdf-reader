# coding: utf-8



describe PDF::Reader::GlyphHash, "#name_to_unicode" do

  it "should correctly map a standard glyph name to unicode" do
    map = PDF::Reader::GlyphHash.new
    expect(map.name_to_unicode(:a)).to eql(0x0061)
    expect(map.name_to_unicode(:e)).to eql(0x0065)
    expect(map.name_to_unicode(:A)).to eql(0x0041)
    expect(map.name_to_unicode(:holam)).to eql(0x05B9)
    expect(map.name_to_unicode(:zukatakana)).to eql(0x30BA)
  end

  it "should correctly map a glyph name with underscores to unicode" do
    map = PDF::Reader::GlyphHash.new
    expect(map.name_to_unicode(:f_i)).to eql(map.name_to_unicode(:fi))
  end

  it "should correctly map a uniHHHH glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    expect(map.name_to_unicode(:uni0032)).to eql(0x0032)
    expect(map.name_to_unicode(:uni1234)).to eql(0x1234)
  end

  it "should correctly map a uHHHH glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    expect(map.name_to_unicode(:u0032)).to   eql(0x0032)
    expect(map.name_to_unicode(:u1234)).to   eql(0x1234)
    expect(map.name_to_unicode(:u12345)).to  eql(0x12345)
    expect(map.name_to_unicode(:u123456)).to eql(0x123456)
  end

  it "should correctly map a Ann glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    expect(map.name_to_unicode(:A65)).to     eql(65)
    expect(map.name_to_unicode(:g3)).to      eql(3)
    expect(map.name_to_unicode(:g65)).to     eql(65)
    expect(map.name_to_unicode(:G65)).to     eql(65)
    expect(map.name_to_unicode(:G655)).to    eql(655)
    expect(map.name_to_unicode(:G6555)).to   eql(6555)
    expect(map.name_to_unicode(:G20000)).to  eql(20000)
  end

  it "should correctly map a AAnn glyph to unicode" do
    map = PDF::Reader::GlyphHash.new
    expect(map.name_to_unicode(:AA65)).to     eql(65)
    expect(map.name_to_unicode(:gg65)).to     eql(65)
    expect(map.name_to_unicode(:GG65)).to     eql(65)
    expect(map.name_to_unicode(:GG655)).to    eql(655)
    expect(map.name_to_unicode(:GG6555)).to   eql(6555)
    expect(map.name_to_unicode(:GG20000)).to eql(20000)
  end

end

describe PDF::Reader::GlyphHash, "#unicode_to_name" do

  it "should correctly map a standard glyph name to unicode" do
    map = PDF::Reader::GlyphHash.new
    expect(map.unicode_to_name(0x0061)).to eql([:a])
    expect(map.unicode_to_name(0x0065)).to eql([:e])
    expect(map.unicode_to_name(0x0041)).to eql([:A])
    expect(map.unicode_to_name(0x05B9)).to eql(
      [:afii57806, :holam, :holam19, :holam26,
      :holam32, :holamhebrew, :holamnarrowhebrew,
      :holamquarterhebrew, :holamwidehebrew]
    )
    expect(map.unicode_to_name(0x20AC)).to eql([:Euro, :euro])
    expect(map.unicode_to_name(0x30BA)).to eql([:zukatakana])
    expect(map.unicode_to_name(157)).to eql([])
  end
end
