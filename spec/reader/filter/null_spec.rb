# coding: utf-8

require File.dirname(__FILE__) + "/../../spec_helper"

describe PDF::Reader::Filter::Null do
  it "returns the data unchanged" do
    filter = PDF::Reader::Filter::Null.new
    expect(filter.filter("\x00")).to eql("\x00")
  end
end
