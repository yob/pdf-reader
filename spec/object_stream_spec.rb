# coding: utf-8

require "spec_helper"

describe Marron::ObjectStream, "[] method" do

  before(:each) do
    @hash = {:N=>2, :Type=>:ObjStm, :First=>11}
    @data = "29 0 30 48 <</K 30 0 R/RoleMap 31 0 R/Type/StructTreeRoot>><</P 29 0 R/S/Document>>"
  end

  it "should provide access to 2 embedded objects" do
    stream = Marron::Stream.new(@hash, @data)
    obj_stream = Marron::ObjectStream.new(stream)

    obj_stream[29].should be_a_kind_of(::Hash)
    obj_stream[30].should be_a_kind_of(::Hash)

    obj_stream[29][:Type].should eql(:StructTreeRoot)
    obj_stream[30][:S].should eql(:Document)
  end

  it "should return nil for objects it doesn't contain" do
    stream = Marron::Stream.new(@hash, @data)
    obj_stream = Marron::ObjectStream.new(stream)

    obj_stream[1].should be_nil
  end

end

describe Marron::ObjectStream, "size method" do

  before(:each) do
    @hash = {:N=>2, :Type=>:ObjStm, :First=>11}
    @data = "29 0 30 48 <</K 30 0 R/RoleMap 31 0 R/Type/StructTreeRoot>><</P 29 0 R/S/Document>>"
  end

  it "should return the number of embedded objects" do
    stream = Marron::Stream.new(@hash, @data)
    obj_stream = Marron::ObjectStream.new(stream)

    obj_stream.size.should eql(2)
  end

end
