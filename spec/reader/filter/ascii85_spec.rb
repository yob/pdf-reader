# coding: utf-8

require File.dirname(__FILE__) + "/../../spec_helper"

describe PDF::Reader::Filter::Ascii85 do
  it "should filter a ASCII85 stream correctly" do
    filter = PDF::Reader::Filter::Ascii85.new
    encoded_data = Ascii85::encode("Ruby")
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCII85 stream missing <~ correctly" do
    filter = PDF::Reader::Filter::Ascii85.new
    encoded_data = Ascii85::encode("Ruby")[2,100]
    filter.filter(encoded_data).should eql("Ruby")
  end
end
