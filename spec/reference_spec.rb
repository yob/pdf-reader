# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::Reference, "hash method" do

  it "should return the same hash for 2 identical objects" do
    one = PDF::Reader::Reference.new(1,0)
    two = PDF::Reader::Reference.new(1,0)

    expect(one.hash).to eq(two.hash)
  end

end

describe PDF::Reader::Reference, "== method" do

  it "should return true for the same object" do
    one = PDF::Reader::Reference.new(1,0)

    expect(one == one).to be_true
  end

  it "should return true for 2 identical objects" do
    one = PDF::Reader::Reference.new(1,0)
    two = PDF::Reader::Reference.new(1,0)

    expect(one == two).to be_true
  end

  it "should return false if one object isn't a Reference" do
    one = PDF::Reader::Reference.new(1,0)

    expect(one == "two").to be_false
  end

end
