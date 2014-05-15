# coding: utf-8

require File.dirname(__FILE__) + "/../../spec_helper"

describe PDF::Reader::Filter::AsciiHex do
  it "should filter a ASCIIHex stream correctly" do
    filter = PDF::Reader::Filter::AsciiHex.new
    encoded_data = "<52756279>"
    expect(filter.filter(encoded_data)).to eql("Ruby")
  end

  it "should filter a ASCIIHex stream missing delimiters" do
    filter = PDF::Reader::Filter::AsciiHex.new
    encoded_data = "52756279"
    expect(filter.filter(encoded_data)).to eql("Ruby")
  end

  it "should filter a ASCIIHex stream with an odd number of nibbles" do
    filter = PDF::Reader::Filter::AsciiHex.new
    encoded_data = "5275627"
    expect(filter.filter(encoded_data)).to eql("Rubp")
  end
end
