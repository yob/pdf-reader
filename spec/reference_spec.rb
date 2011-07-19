# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Reference, "hash method" do

  it "should return the same hash for 2 identical objects" do
    one = PDF::Reader::Reference.new(1,0)
    two = PDF::Reader::Reference.new(1,0)

    one.hash.should == two.hash
  end

end

describe PDF::Reader::Reference, "== method" do

  it "should return true for the same object" do
    one = PDF::Reader::Reference.new(1,0)

    (one == one).should be_true
  end

  it "should return true for 2 identical objects" do
    one = PDF::Reader::Reference.new(1,0)
    two = PDF::Reader::Reference.new(1,0)

    (one == two).should be_true
  end

  it "should return false if one object isn't a Reference" do
    one = PDF::Reader::Reference.new(1,0)

    (one == "two").should be_false
  end

end
