# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"
require 'pdf/reader/synchronized_cache'

describe PDF::Reader::SynchronizedCache, "#[]=" do
  let(:cache) { PDF::Reader::SynchronizedCache.new }

  it "should store a value" do
    cache[:foo] = :bar
  end

end

describe PDF::Reader::SynchronizedCache, "#[]" do
  let(:cache) { PDF::Reader::SynchronizedCache.new }

  it "should return a stored value" do
    cache[:foo] = :bar
    cache[:foo].should == :bar
  end

end
