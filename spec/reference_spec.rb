# coding: utf-8

$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Reference, "hash method" do

  it "should return the same hash for 2 identical objects" do
    one = PDF::Reader::Reference.new(1,0)
    two = PDF::Reader::Reference.new(1,0)

    one.hash.should == two.hash
  end
end
