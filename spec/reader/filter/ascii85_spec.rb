# coding: utf-8

require File.dirname(__FILE__) + "/../../spec_helper"

describe PDF::Reader::Filter::Ascii85 do
  it "should filter a ASCII85 stream correctly" do
    filter = PDF::Reader::Filter::Ascii85.new
    encoded_data = Ascii85::encode("Ruby")
    expect(filter.filter(encoded_data)).to eql("Ruby")
  end

  it "should filter a ASCII85 stream missing <~ correctly" do
    filter = PDF::Reader::Filter::Ascii85.new
    encoded_data = Ascii85::encode("Ruby")[2,100]
    expect(filter.filter(encoded_data)).to eql("Ruby")
  end
end
