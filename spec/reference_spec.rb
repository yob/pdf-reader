# coding: utf-8

require "spec_helper"

describe Marron::Reference, "hash method" do

  it "should return the same hash for 2 identical objects" do
    one = Marron::Reference.new(1,0)
    two = Marron::Reference.new(1,0)

    one.hash.should == two.hash
  end

end

describe Marron::Reference, "== method" do

  it "should return true for the same object" do
    one = Marron::Reference.new(1,0)

    (one == one).should be_true
  end

  it "should return true for 2 identical objects" do
    one = Marron::Reference.new(1,0)
    two = Marron::Reference.new(1,0)

    (one == two).should be_true
  end

  it "should return false if one object isn't a Reference" do
    one = Marron::Reference.new(1,0)

    (one == "two").should be_false
  end

end
