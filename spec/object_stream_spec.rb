# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::ObjectStream, "[] method" do

  before(:each) do
    @hash = {:N=>2, :Type=>:ObjStm, :First=>11}
    @data = "29 0 30 48 <</K 30 0 R/RoleMap 31 0 R/Type/StructTreeRoot>><</P 29 0 R/S/Document>>"
  end

  it "should provide access to 2 embedded objects" do
    stream = PDF::Reader::Stream.new(@hash, @data)
    obj_stream = PDF::Reader::ObjectStream.new(stream)

    obj_stream[29].should be_a_kind_of(::Hash)
    obj_stream[30].should be_a_kind_of(::Hash)

    obj_stream[29][:Type].should eql(:StructTreeRoot)
    obj_stream[30][:S].should eql(:Document)
  end

  it "should return nil for objects it doesn't contain" do
    stream = PDF::Reader::Stream.new(@hash, @data)
    obj_stream = PDF::Reader::ObjectStream.new(stream)

    obj_stream[1].should be_nil
  end

end

describe PDF::Reader::ObjectStream, "size method" do

  before(:each) do
    @hash = {:N=>2, :Type=>:ObjStm, :First=>11}
    @data = "29 0 30 48 <</K 30 0 R/RoleMap 31 0 R/Type/StructTreeRoot>><</P 29 0 R/S/Document>>"
  end

  it "should return the number of embedded objects" do
    stream = PDF::Reader::Stream.new(@hash, @data)
    obj_stream = PDF::Reader::ObjectStream.new(stream)

    obj_stream.size.should eql(2)
  end

end
