# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

class PDF::Reader::CMap
  attr_reader :map
end

describe "PDF::Reader::CMap with a bfchar cmap" do

  it "should correctly load a cmap object string" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfchar.txt"
    map = PDF::Reader::CMap.new(File.read(filename))
    map.map.should be_a_kind_of(Hash)
    map.size.should     eql(9)
    map.map[0x1].should eql(0x48)
    map.map[0x2].should eql(0x65)
    map.map[0x9].should eql(0x73)
  end

  it "should correctly convert a character code into a unicode codepoint" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfchar.txt"
    map = PDF::Reader::CMap.new(File.read(filename))
    map.decode(0x1).should eql(0x48)
    map.decode(0x2).should eql(0x65)
    map.decode(0x9).should eql(0x73)
  end

  it "should correctly load a cmap that uses the beginbfrange operator" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange.txt"
    map = PDF::Reader::CMap.new(File.read(filename))
    map.decode(0x16C9).should eql(0x4F38) # mapped with the bfchar operator
    map.decode(0x0003).should eql(0x0020) # mapped with the bfrange operator
    map.decode(0x0004).should eql(0x0020+1) # mapped with the bfrange operator
    map.decode(0x0005).should eql(0x0020+2) # mapped with the bfrange operator
  end

  it "should correctly load a cmap that uses the beginbfrange operator" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange_two.txt"
    map = PDF::Reader::CMap.new(File.read(filename))
    map.decode(0x0100).should eql(0x0100) # mapped with the bfrange operator
  end
  
  it "should correctly load a cmap that uses the beginbfrange operator with the array syntax" do
    filename = File.dirname(__FILE__) + "/data/cmap_with_bfrange_three.txt"
    map = PDF::Reader::CMap.new(File.read(filename))

    map.size.should eql(256)
    map.decode(0x00).should eql(0xfffd) # mapped with the bfrange operator
    map.decode(0x01).should eql(0x0050) # mapped with the bfrange operator
    map.decode(0x03).should eql(0x0067) # mapped with the bfrange operator
    map.decode(0x08).should eql(0x0073) # mapped with the bfrange operator
  end

end
