# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe "PDF::Reader::CMap with a bfchar cmap" do

  it "should correctly load a cmap object string" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfchar.txt"
    map = PDF::Reader::CMap.new(binread(filename))
    map.map.should be_a_kind_of(Hash)
    map.size.should     == 9
    map.map[0x1].should == [0x48]
    map.map[0x2].should == [0x65]
    map.map[0x9].should == [0x73]
  end

  it "should correctly convert a character code into a unicode codepoint" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfchar.txt"
    map = PDF::Reader::CMap.new(binread(filename))
    map.decode(0x1).should == [0x48]
    map.decode(0x2).should == [0x65]
    map.decode(0x9).should == [0x73]
  end

  it "should correctly load a cmap that uses the beginbfrange operator" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange.txt"
    map = PDF::Reader::CMap.new(binread(filename))
    map.decode(0x16C9).should == [0x4F38] # mapped with the bfchar operator
    map.decode(0x0003).should == [0x0020] # mapped with the bfrange operator
    map.decode(0x0004).should == [0x0020+1] # mapped with the bfrange operator
    map.decode(0x0005).should == [0x0020+2] # mapped with the bfrange operator
  end

  it "should correctly load a cmap that uses the beginbfrange operator" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange_two.txt"
    map = PDF::Reader::CMap.new(binread(filename))
    map.decode(0x0100).should == [0x0100] # mapped with the bfrange operator
  end

  it "should correctly load a cmap that uses the beginbfrange operator with the array syntax" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange_three.txt"
    map = PDF::Reader::CMap.new(binread(filename))

    map.size.should eql(256)
    map.decode(0x00).should == [0xfffd] # mapped with the bfrange operator
    map.decode(0x01).should == [0x0050] # mapped with the bfrange operator
    map.decode(0x03).should == [0x0067] # mapped with the bfrange operator
    map.decode(0x08).should == [0x0073] # mapped with the bfrange operator
  end

  it "should correctly load a cmap that has ligatures in it" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_ligatures.txt"
    map = PDF::Reader::CMap.new(binread(filename))

    map.decode(0x00B7).should eql([0x2019])
    map.decode(0x00C0).should eql([0x66, 0x69])
    map.decode(0x00C1).should eql([0x66, 0x6C])
  end

  it "should correctly load a cmap that has surrogate pairs in it" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_surrogate_pairs.txt"
    map = PDF::Reader::CMap.new(binread(filename))

    map.decode(0x0502).should eql([0x03D1])
    map.decode(0x0C09).should eql([0x1D6FD])
    map.decode(0x0723).should eql([0x1D434])
    map.decode(0x0C23).should eql([0x1D717])
    map.decode(0x0526).should eql([0x20D7])
    map.decode(0x072B).should eql([0x1D43C])
    map.decode(0x122C).should eql([0xFFFD])
  end

  it "should correctly load a cmap that has a bfrange with > 255 characters" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_large_bfrange.txt"
    map = PDF::Reader::CMap.new(binread(filename))

    map.decode(0x00B7).should eql([0x00B7])
    map.decode(0x00C0).should eql([0x00C0])
    map.decode(0x00C1).should eql([0x00C1])
  end

end
