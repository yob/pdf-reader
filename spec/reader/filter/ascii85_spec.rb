# coding: utf-8

require "spec_helper"

describe Marron::Filter::Ascii85 do
  it "should filter a ASCII85 stream correctly" do
    filter = Marron::Filter::Ascii85.new
    encoded_data = Ascii85::encode("Ruby")
    filter.filter(encoded_data).should eql("Ruby")
  end

  it "should filter a ASCII85 stream missing <~ correctly" do
    filter = Marron::Filter::Ascii85.new
    encoded_data = Ascii85::encode("Ruby")[2,100]
    filter.filter(encoded_data).should eql("Ruby")
  end
end
