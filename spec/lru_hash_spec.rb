# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader::LruHash  do
  let!(:cache) { PDF::Reader::LruHash.new(2) }

  describe "When cache size is exceed by one" do

    before do
      cache[:a] = 'a'
      cache[:b] = 'b'
      cache[:c] = 'c'
    end

    it "should have evicted oldest item" do
      cache[:a].should be_nil
      cache[:b].should == 'b'
      cache[:c].should == 'c'
    end
  end

  describe "When cache size is exceed by one" do

    before do
      cache[:a] = 'a'
      cache[:b] = 'b'
      cache[:a]
      cache[:c] = 'c'
    end

    it "should have evicted oldest item" do
      cache[:a].should == 'a'
      cache[:b].should be_nil
      cache[:c].should == 'c'
    end
  end

  describe "When cache size is exceed by one" do

    before do
      cache[:a] = 'a'
      cache[:b] = 'b'
      cache[:a] = 'a'
      cache[:c] = 'c'
    end

    it "should have evicted oldest item" do
      cache[:a].should == 'a'
      cache[:b].should be_nil
      cache[:c].should == 'c'
    end
  end
end
